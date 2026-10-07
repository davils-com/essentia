/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia/src/flow/flow_collector.dart';
import 'package:essentia/src/flow/flow_subscriber.dart';
import 'package:essentia/src/flow/mutable_shared_flow.dart';
import 'package:essentia/src/flow/mutable_state_flow.dart';
import 'package:essentia/src/flow/readonly_shared_flow.dart';
import 'package:essentia/src/flow/readonly_state_flow.dart';
import 'package:essentia/src/flow/shared_flow.dart';
import 'package:essentia/src/flow/state_flow.dart';
import 'package:essentia/src/flow/state_flow_slot.dart';
import 'package:meta/meta.dart';

/// The state flow behind `MutableStateFlow`, Kotlin's `StateFlowImpl`.
///
/// Every listener has a pending flag that a change sets; its pump then
/// delivers the value current at that moment, unless it equals the value
/// it delivered last.
@internal
final class StateFlowImpl<T> extends Stream<T> implements MutableStateFlow<T> {
  /// Creates the flow holding [_value].
  StateFlowImpl(this._value);

  /// The current value.
  T _value;

  /// The places of the current listeners.
  final _slots = <StateFlowSlot>[];

  /// The count of listeners, created when somebody asks for it.
  StateFlowImpl<int>? _subscriptionCount;

  /// A state flow is a broadcast stream.
  @override
  bool get isBroadcast => true;

  /// See [Stream.value].
  @override
  T get value => _value;

  /// See [Stream.value].
  @override
  set value(T value) => _updateState(null, value);

  /// See [SharedFlow.replayCache].
  @override
  List<T> get replayCache => List<T>.unmodifiable(<T>[_value]);

  /// See [MutableSharedFlow.subscriptionCount].
  @override
  StateFlow<int> get subscriptionCount =>
      (_subscriptionCount ??= StateFlowImpl<int>(_slots.length)).asStateFlow();

  /// Subscribes a listener, which starts with the current value.
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

  /// See [MutableStateFlow.compareAndSet].
  @override
  bool compareAndSet(T expect, T update) =>
      _updateState((value: expect), update);

  /// See [FlowCollector.emit].
  @override
  Future<void> emit(T value) {
    _updateState(null, value);
    return Future<void>.value();
  }

  /// See [MutableStateFlow.tryEmit].
  @override
  bool tryEmit(T value) {
    _updateState(null, value);
    return true;
  }

  /// See [MutableStateFlow.resetReplayCache].
  @override
  void resetReplayCache() => throw UnsupportedError(
    'MutableStateFlow.resetReplayCache is not supported',
  );

  /// See [MutableSharedFlow.asSharedFlow].
  @override
  SharedFlow<T> asSharedFlow() => ReadonlySharedFlow<T>(this);

  /// See [MutableStateFlow.asStateFlow].
  @override
  StateFlow<T> asStateFlow() => ReadonlyStateFlow<T>(this);

  /// Renders the current value.
  @override
  String toString() => 'MutableStateFlow($_value)';

  /// Sets the value to [newValue] if the current one equals [expected],
  /// or in any case without one, Kotlin's `updateState`.
  ///
  /// Returns whether the current value matched.
  bool _updateState(({T value})? expected, T newValue) {
    final T current = _value;
    if (expected != null && current != expected.value) {
      return false;
    }
    if (current == newValue) {
      return true;
    }
    _value = newValue;
    for (final StateFlowSlot slot in _slots) {
      slot.pending = true;
      slot.wake?.call();
    }
    return true;
  }

  /// Hooks a new listener behind [controller] up.
  void _subscribe(MultiStreamController<T> controller) {
    final slot = StateFlowSlot();
    ({T value})? delivered;
    _slots.add(slot);
    _subscriptionCount?.value = _slots.length;
    final subscriber = FlowSubscriber<T>(
      controller,
      () {
        if (!slot.pending) {
          return null;
        }
        slot.pending = false;
        final T current = _value;
        final last = delivered;
        if (last != null && last.value == current) {
          return null;
        }
        return delivered = (value: current);
      },
      () {
        _slots.remove(slot);
        _subscriptionCount?.value = _slots.length;
      },
    );
    slot.wake = subscriber.wake;
    subscriber.start();
  }
}
