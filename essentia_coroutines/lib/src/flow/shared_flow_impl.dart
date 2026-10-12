/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';
import 'dart:math';

import 'package:essentia_coroutines/src/channels/buffer_overflow.dart';
import 'package:essentia_coroutines/src/continuation/cancellable_continuation.dart';
import 'package:essentia_coroutines/src/continuation/suspension.dart';
import 'package:essentia_coroutines/src/flow/flow_collector.dart';
import 'package:essentia_coroutines/src/flow/flow_subscriber.dart';
import 'package:essentia_coroutines/src/flow/mutable_shared_flow.dart';
import 'package:essentia_coroutines/src/flow/readonly_shared_flow.dart';
import 'package:essentia_coroutines/src/flow/shared_flow.dart';
import 'package:essentia_coroutines/src/flow/shared_flow_emitter.dart';
import 'package:essentia_coroutines/src/flow/shared_flow_slot.dart';
import 'package:essentia_coroutines/src/flow/state_flow.dart';
import 'package:essentia_coroutines/src/flow/state_flow_impl.dart';
import 'package:meta/meta.dart';

/// Marks a place of the buffer whose emitter was cancelled or moved on,
/// Kotlin's `NO_VALUE`.
const _noValue = Object();

/// The shared flow behind `MutableSharedFlow`, Kotlin's `SharedFlowImpl`.
///
/// The buffer holds the values at the indices from the head on, followed
/// by the queue of emitters waiting for room. The head is the smaller of
/// the replay index, where a new listener starts, and the smallest index a
/// listener still has to take. The bookkeeping is Kotlin's, one to one; an
/// isolate runs one thing at a time, so nothing is locked.
@internal
final class SharedFlowImpl<T> extends Stream<T>
    implements MutableSharedFlow<T> {
  /// Creates a flow replaying [_replay] values out of a buffer of
  /// [_bufferCapacity], overflowing as [_onBufferOverflow] says.
  SharedFlowImpl(this._replay, this._bufferCapacity, this._onBufferOverflow);

  /// How many values a new listener gets first.
  final int _replay;

  /// How many values the buffer holds: replay and extra capacity.
  final int _bufferCapacity;

  /// What happens when the buffer is full.
  final BufferOverflow _onBufferOverflow;

  /// The values and waiting emitters, in a ring whose size is a power of
  /// two.
  var _buffer = <Object?>[];

  /// The index from which a new listener takes values.
  var _replayIndex = 0;

  /// The smallest index a listener still has to take, the replay index
  /// while nobody listens.
  var _minCollectorIndex = 0;

  /// How many values are buffered.
  var _bufferSize = 0;

  /// How many emitters wait.
  var _queueSize = 0;

  /// The places of the current listeners.
  final _slots = <SharedFlowSlot>[];

  /// The count of listeners, created when somebody asks for it.
  StateFlowImpl<int>? _subscriptionCount;

  /// The smallest index the buffer holds.
  int get _head => min(_minCollectorIndex, _replayIndex);

  /// How many buffered values a new listener gets.
  int get _replaySize => _head + _bufferSize - _replayIndex;

  /// How many places of the buffer are taken.
  int get _totalSize => _bufferSize + _queueSize;

  /// The index after the last buffered value.
  int get _bufferEndIndex => _head + _bufferSize;

  /// The index after the last waiting emitter.
  int get _queueEndIndex => _head + _bufferSize + _queueSize;

  /// A shared flow is a broadcast stream.
  @override
  bool get isBroadcast => true;

  /// See [SharedFlow.replayCache].
  @override
  List<T> get replayCache {
    final int size = _replaySize;
    return List<T>.unmodifiable(<T>[
      for (var offset = 0; offset < size; offset++)
        _bufferAt(_replayIndex + offset) as T,
    ]);
  }

  /// See [MutableSharedFlow.subscriptionCount].
  @override
  StateFlow<int> get subscriptionCount =>
      (_subscriptionCount ??= StateFlowImpl<int>(_slots.length)).asStateFlow();

  /// Subscribes a listener, which starts with the replay values.
  ///
  /// Returns the subscription.
  @override
  StreamSubscription<T> listen(
    void Function(T event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<T>.multi(_subscribe, isBroadcast: true).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  /// See [MutableSharedFlow.tryEmit].
  @override
  bool tryEmit(T value) {
    if (!_tryEmitLocked(value)) {
      return false;
    }
    _wakeSlots();
    return true;
  }

  /// See [FlowCollector.emit].
  @override
  Future<void> emit(T value) {
    if (tryEmit(value)) {
      return Future<void>.value();
    }
    return _emitSuspend(value);
  }

  /// See [MutableSharedFlow.resetReplayCache].
  @override
  void resetReplayCache() => _updateBuffer(
    _bufferEndIndex,
    _minCollectorIndex,
    _bufferEndIndex,
    _queueEndIndex,
  );

  /// See [MutableSharedFlow.asSharedFlow].
  @override
  SharedFlow<T> asSharedFlow() => ReadonlySharedFlow<T>(this);

  /// Renders the sizes of the flow.
  @override
  String toString() =>
      'MutableSharedFlow(replay: $_replay, buffered: $_bufferSize, '
      'waiting emitters: $_queueSize, listeners: ${_slots.length})';

  /// Hooks a new listener behind [controller] up.
  void _subscribe(MultiStreamController<T> controller) {
    final slot = SharedFlowSlot(_newCollectorIndex());
    _slots.add(slot);
    _subscriptionCount?.value = _slots.length;
    final subscriber = FlowSubscriber<T>(
      controller,
      () => _tryTakeValue(slot),
      () => _freeSlot(slot),
    );
    slot.wake = subscriber.wake;
    subscriber.start();
  }

  /// Takes the place of a listener back.
  void _freeSlot(SharedFlowSlot slot) {
    final int oldIndex = slot.index;
    slot
      ..index = -1
      ..waiting = false;
    _slots.remove(slot);
    _subscriptionCount?.value = _slots.length;
    _resume(_updateCollectorIndex(oldIndex));
  }

  /// Emits [value] if that needs no waiting, Kotlin's `tryEmitLocked`.
  ///
  /// Returns whether the value is taken care of.
  bool _tryEmitLocked(T value) {
    if (_slots.isEmpty) {
      return _tryEmitNoCollectors(value);
    }
    if (_bufferSize >= _bufferCapacity && _minCollectorIndex <= _replayIndex) {
      switch (_onBufferOverflow) {
        case BufferOverflow.suspend:
          return false;
        case BufferOverflow.dropLatest:
          return true;
        case BufferOverflow.dropOldest:
          break;
      }
    }
    _enqueue(value);
    _bufferSize++;
    if (_bufferSize > _bufferCapacity) {
      _dropOldest();
    }
    if (_replaySize > _replay) {
      _updateBuffer(
        _replayIndex + 1,
        _minCollectorIndex,
        _bufferEndIndex,
        _queueEndIndex,
      );
    }
    return true;
  }

  /// Keeps [value] for replay only, as nobody listens.
  ///
  /// Returns `true`.
  bool _tryEmitNoCollectors(T value) {
    if (_replay == 0) {
      return true;
    }
    _enqueue(value);
    _bufferSize++;
    if (_bufferSize > _replay) {
      _dropOldest();
    }
    _minCollectorIndex = _head + _bufferSize;
    return true;
  }

  /// Drops the oldest buffered value, moving lagging listeners on.
  void _dropOldest() {
    _setBufferAt(_head, null);
    _bufferSize--;
    final int newHead = _head + 1;
    if (_replayIndex < newHead) {
      _replayIndex = newHead;
    }
    if (_minCollectorIndex < newHead) {
      for (final SharedFlowSlot slot in _slots) {
        if (slot.index >= 0 && slot.index < newHead) {
          slot.index = newHead;
        }
      }
      _minCollectorIndex = newHead;
    }
  }

  /// Puts [item] behind everything the buffer holds; the caller counts it
  /// as a value or as an emitter.
  void _enqueue(Object? item) {
    final int size = _totalSize;
    if (size >= _buffer.length) {
      _grow(size, max(2, _buffer.length * 2));
    }
    _setBufferAt(_head + size, item);
  }

  /// Moves the [size] taken places into a ring of [capacity].
  void _grow(int size, int capacity) {
    final grown = List<Object?>.filled(capacity, null);
    final int head = _head;
    for (var offset = 0; offset < size; offset++) {
      grown[(head + offset) % capacity] = _bufferAt(head + offset);
    }
    _buffer = grown;
  }

  /// The item at [index].
  ///
  /// Returns it.
  Object? _bufferAt(int index) => _buffer[index % _buffer.length];

  /// Puts [item] at [index].
  void _setBufferAt(int index, Object? item) =>
      _buffer[index % _buffer.length] = item;

  /// Queues an emitter of [value] until there is room, Kotlin's
  /// `emitSuspend`.
  ///
  /// Kotlin checks for room once more under its lock; an isolate runs one
  /// thing at a time, so the failed `tryEmit` right before still holds.
  ///
  /// Returns a future that completes once the value is in the buffer.
  Future<void> _emitSuspend(T value) => suspendCancellableCoroutine<void>((it) {
    final emitter = SharedFlowEmitter(
      index: _head + _totalSize,
      value: value,
      continuation: it,
    );
    _enqueue(emitter);
    _queueSize++;
    if (_bufferCapacity == 0) {
      _wakeSlots();
    }
    it.invokeOnCancellation((cause) => _cancelEmitter(emitter));
  });

  /// Takes a cancelled [emitter] out of the queue.
  void _cancelEmitter(SharedFlowEmitter emitter) {
    if (emitter.index < _head) {
      return;
    }
    if (!identical(_bufferAt(emitter.index), emitter)) {
      return;
    }
    _setBufferAt(emitter.index, _noValue);
    _cleanupTail();
  }

  /// The index a new listener starts at.
  ///
  /// Returns the replay index.
  int _newCollectorIndex() {
    final int index = _replayIndex;
    if (index < _minCollectorIndex) {
      _minCollectorIndex = index;
    }
    return index;
  }

  /// Moves the buffer on after a listener moved on from, or left, the
  /// index [oldIndex], Kotlin's `updateCollectorIndexLocked`.
  ///
  /// Returns the emitters that found room and are to be resumed.
  List<CancellableContinuation<void>> _updateCollectorIndex(int oldIndex) {
    if (oldIndex > _minCollectorIndex) {
      return const <CancellableContinuation<void>>[];
    }
    final int head = _head;
    int newMinCollectorIndex = head + _bufferSize;
    if (_bufferCapacity == 0 && _queueSize > 0) {
      newMinCollectorIndex++;
    }
    for (final SharedFlowSlot slot in _slots) {
      if (slot.index >= 0 && slot.index < newMinCollectorIndex) {
        newMinCollectorIndex = slot.index;
      }
    }
    if (newMinCollectorIndex <= _minCollectorIndex) {
      return const <CancellableContinuation<void>>[];
    }
    int newBufferEndIndex = _bufferEndIndex;
    final int maxResumeCount = _slots.isEmpty
        ? _queueSize
        : _passedCancelledEmitter()
        ? 0
        : min(
            _queueSize,
            _bufferCapacity - (newBufferEndIndex - newMinCollectorIndex),
          );
    final resumes = <CancellableContinuation<void>>[];
    final int newQueueEndIndex = newBufferEndIndex + _queueSize;
    for (
      var index = newBufferEndIndex;
      index < newQueueEndIndex && resumes.length < maxResumeCount;
      index++
    ) {
      final Object? item = _bufferAt(index);
      if (item is SharedFlowEmitter) {
        resumes.add(item.continuation);
        _setBufferAt(index, _noValue);
        _setBufferAt(newBufferEndIndex, item.value);
        newBufferEndIndex++;
      }
    }
    final int newBufferSize = newBufferEndIndex - head;
    if (_slots.isEmpty) {
      newMinCollectorIndex = newBufferEndIndex;
    }
    int newReplayIndex = max<int>(
      _replayIndex,
      newBufferEndIndex - min<int>(_replay, newBufferSize),
    );
    if (_bufferCapacity == 0 &&
        newReplayIndex < newQueueEndIndex &&
        identical(_bufferAt(newReplayIndex), _noValue)) {
      newBufferEndIndex++;
      newReplayIndex++;
    }
    _updateBuffer(
      newReplayIndex,
      newMinCollectorIndex,
      newBufferEndIndex,
      newQueueEndIndex,
    );
    _cleanupTail();
    if (resumes.isNotEmpty) {
      _wakeSlots();
    }
    return resumes;
  }

  /// Whether the listeners of a flow without a buffer moved past the first
  /// queued emitter, which was cancelled.
  ///
  /// Nobody is to be resumed for it then: Kotlin's bookkeeping would hand
  /// the room it left to the next emitter, whose value nobody took yet, and
  /// lose that value.
  ///
  /// Returns whether that is the case.
  bool _passedCancelledEmitter() =>
      _bufferCapacity == 0 &&
      _queueSize > 0 &&
      identical(_bufferAt(_bufferEndIndex), _noValue);

  /// Sets the indices of the buffer, clearing what falls behind the new
  /// head, Kotlin's `updateBufferLocked`.
  void _updateBuffer(
    int newReplayIndex,
    int newMinCollectorIndex,
    int newBufferEndIndex,
    int newQueueEndIndex,
  ) {
    final int newHead = min(newMinCollectorIndex, newReplayIndex);
    for (int index = _head; index < newHead; index++) {
      _setBufferAt(index, null);
    }
    _replayIndex = newReplayIndex;
    _minCollectorIndex = newMinCollectorIndex;
    _bufferSize = newBufferEndIndex - newHead;
    _queueSize = newQueueEndIndex - newBufferEndIndex;
  }

  /// Drops the cancelled emitters at the end of the queue, Kotlin's
  /// `cleanupTailLocked`.
  void _cleanupTail() {
    if (_bufferCapacity == 0 && _queueSize <= 1) {
      return;
    }
    while (_queueSize > 0 &&
        identical(_bufferAt(_head + _totalSize - 1), _noValue)) {
      _queueSize--;
      _setBufferAt(_head + _totalSize, null);
    }
  }

  /// Takes the next value for the listener of [slot], or marks it waiting,
  /// Kotlin's `tryTakeValue`; the place of a cancelled emitter it meets on
  /// the way is skipped.
  ///
  /// Returns the value, or `null` when there is none yet.
  ({T value})? _tryTakeValue(SharedFlowSlot slot) {
    while (true) {
      final int index = _tryPeek(slot);
      if (index < 0) {
        slot.waiting = true;
        return null;
      }
      final int oldIndex = slot.index;
      final Object? item = _bufferAt(index);
      slot.index = index + 1;
      _resume(_updateCollectorIndex(oldIndex));
      if (!identical(item, _noValue)) {
        return (value: (item is SharedFlowEmitter ? item.value : item) as T);
      }
    }
  }

  /// The index of the value the listener of [slot] can take now, Kotlin's
  /// `tryPeekLocked`.
  ///
  /// Returns the index, or `-1` when it has to wait.
  int _tryPeek(SharedFlowSlot slot) {
    final int index = slot.index;
    if (index < _bufferEndIndex) {
      return index;
    }
    if (_bufferCapacity > 0 || index > _head || _queueSize == 0) {
      return -1;
    }
    return index;
  }

  /// Wakes the waiting listeners that can take a value now, Kotlin's
  /// `findSlotsToResumeLocked`.
  void _wakeSlots() {
    for (final SharedFlowSlot slot in _slots) {
      if (slot.waiting && _tryPeek(slot) >= 0) {
        slot.waiting = false;
        slot.wake?.call();
      }
    }
  }

  /// Resumes the emitters in [resumes].
  static void _resume(List<CancellableContinuation<void>> resumes) {
    for (final emitter in resumes) {
      emitter.resume(null);
    }
  }
}
