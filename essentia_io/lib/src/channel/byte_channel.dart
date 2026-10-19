/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:essentia_io/src/buffer/buffer.dart';
import 'package:essentia_io/src/channel/byte_read_channel.dart';
import 'package:essentia_io/src/channel/byte_write_channel.dart';
import 'package:essentia_io/src/channel/internal/channel_slot.dart';
import 'package:essentia_io/src/channel/internal/close_token.dart';
import 'package:essentia_io/src/exception/closed_read_channel_exception.dart';
import 'package:essentia_io/src/exception/closed_write_channel_exception.dart';
import 'package:essentia_io/src/exception/concurrent_io_exception.dart';
import 'package:essentia_io/src/exception/io_exception.dart';

/// A channel a writer and a reader share, Ktor's `ByteChannel`.
///
/// The writer writes to [writeBuffer] and flushes the bytes over to the
/// reader, who reads them from [readBuffer]. Once [maxSize] flushed bytes
/// wait for the reader, a flush waits until the reader takes them: that is
/// the back pressure of the channel. Every wait is cancellable through the
/// job of the coroutine that waits.
///
/// ```dart
/// final channel = ByteChannel();
/// final Job writing = scope.launch((it) async {
///   await channel.writeString('hello');
///   await channel.flushAndClose();
/// });
/// final String text = (await channel.readRemaining()).readString();
/// ```
final class ByteChannel implements ByteReadChannel, ByteWriteChannel {
  /// Creates an open channel; with [autoFlush] every write operation
  /// flushes at once.
  ByteChannel({this.autoFlush = false});

  /// The number of flushed bytes a writer may get ahead of the reader
  /// before a flush waits, 1 MiB, Ktor's `CHANNEL_MAX_SIZE`.
  static const int maxSize = 1024 * 1024;

  /// Whether every write operation flushes at once.
  @override
  final bool autoFlush;

  /// The bytes flushed by the writer and not yet taken by the reader.
  final _flushBuffer = Buffer();

  /// The bytes the reader took and has not read yet.
  final _readBuffer = Buffer();

  /// The bytes written and not flushed yet.
  final _writeBuffer = Buffer();

  /// Who waits on the channel.
  ChannelSlot _slot = const EmptySlot();

  /// How the channel was closed, `null` while it is open.
  CloseToken? _closed;

  /// What runs once the channel is closed, with its cause.
  void Function(Object? cause)? _closeHandler;

  /// Whether the writer may flush without waiting for the reader.
  bool get hasFreeSpace => _flushBuffer.size < maxSize;

  /// Why the channel failed; `null` while it is open and once it was
  /// closed normally.
  @override
  Exception? get closedCause => _closed?.wrapCause();

  /// Whether the channel was closed or cancelled.
  @override
  bool get isClosedForWrite => _closed != null;

  /// Whether every byte is read and the channel was closed, or the
  /// channel failed.
  @override
  bool get isClosedForRead =>
      closedCause != null ||
      (isClosedForWrite && _flushBuffer.exhausted && _readBuffer.exhausted);

  /// The bytes the reader may read, topped up from the flushed bytes once
  /// it is empty.
  ///
  /// Throws a [ClosedReadChannelException] once the channel failed.
  @override
  Buffer get readBuffer {
    _closed?.throwCause(ClosedReadChannelException.new);
    if (_readBuffer.exhausted) {
      _moveFlushToReadBuffer();
    }
    return _readBuffer;
  }

  /// The bytes written and not flushed yet.
  ///
  /// Throws a [ClosedWriteChannelException] once the channel is closed.
  @override
  Buffer get writeBuffer {
    final CloseToken? closed = _closed;
    if (closed != null) {
      closed.throwCause(ClosedWriteChannelException.new);
      throw ClosedWriteChannelException();
    }
    return _writeBuffer;
  }

  /// Waits until at least [min] bytes may be read, or the channel ends.
  ///
  /// Returns `true` when they may, `false` when the channel ended before.
  ///
  /// Throws [closedCause] once the channel failed, a [RangeError] when
  /// [min] is not between 1 and [maxSize], and a [ConcurrentIoException]
  /// when another reader waits too.
  @override
  Future<bool> awaitContent([int min = 1]) async {
    RangeError.checkValueInInterval(min, 1, maxSize, 'min');
    _rethrowCloseCause();
    if (_readBuffer.size >= min) {
      return true;
    }
    await _sleepWhile(
      'read',
      () => _flushBuffer.size + _readBuffer.size < min && _closed == null,
    );
    _rethrowCloseCause();
    if (_readBuffer.size < maxSize) {
      _moveFlushToReadBuffer();
    }
    return _readBuffer.size >= min;
  }

  /// Hands the written bytes to the reader, and waits while [maxSize]
  /// flushed bytes wait for it.
  ///
  /// Throws [closedCause] once the channel failed, and a
  /// [ConcurrentIoException] when another writer waits too.
  @override
  Future<void> flush() async {
    _rethrowCloseCause();
    flushWriteBuffer();
    if (hasFreeSpace) {
      return;
    }
    await _sleepWhile('write', () => !hasFreeSpace && _closed == null);
  }

  /// Hands the written bytes to the reader without waiting, Ktor's
  /// `flushWriteBuffer`.
  void flushWriteBuffer() {
    if (_writeBuffer.exhausted) {
      return;
    }
    _flushBuffer.writeBuffer(_writeBuffer);
    _resumeSlot('read');
  }

  /// Flushes and closes the channel without waiting for the reader.
  void close() {
    flushWriteBuffer();
    if (_closed != null) {
      return;
    }
    _closed = CloseToken.closed;
    _closeSlot(null);
  }

  /// Flushes, waiting for the reader if it must, and closes the channel; a
  /// flush that fails leaves the channel as the failure left it.
  @override
  Future<void> flushAndClose() async {
    try {
      await flush();
    } on Object {
      if (_closed != null) {
        return;
      }
    }
    if (_closed != null) {
      return;
    }
    _closed = CloseToken.closed;
    _closeSlot(null);
  }

  /// Cancels the channel with [cause]: the bytes not read are dropped, and
  /// the reader and the writer fail with it. A channel that is closed
  /// already stays as it is.
  @override
  void cancel([Object? cause]) {
    if (_closed != null) {
      return;
    }
    final token = CloseToken(
      cause ?? const IoException('Channel was cancelled'),
      StackTrace.current,
    );
    _closed = token;
    _flushBuffer.clear();
    _readBuffer.clear();
    _closeSlot(token.wrapCause());
  }

  /// Runs [handler] once the channel is closed, with what it was cancelled
  /// with, `null` for a channel closed normally; at once for a channel that
  /// is closed already, kotlinx.coroutines' `invokeOnClose` of a channel.
  /// The writer learns this way that its reader gave up while it has
  /// nothing to write.
  ///
  /// Throws a [StateError] when a handler is registered already.
  void invokeOnClose(void Function(Object? cause) handler) {
    final CloseToken? closed = _closed;
    if (closed != null) {
      handler(closed.wrapCause());
      return;
    }
    if (_closeHandler != null) {
      throw StateError('Only one close handler is supported per channel');
    }
    _closeHandler = handler;
  }

  /// Describes the channel without its bytes.
  ///
  /// Returns `ByteChannel[<hash>]`.
  @override
  String toString() => 'ByteChannel[${identityHashCode(this)}]';

  /// Throws [closedCause] once the channel failed.
  void _rethrowCloseCause() {
    final Exception? cause = closedCause;
    if (cause != null) {
      throw cause;
    }
  }

  /// Moves the flushed bytes to the reader and wakes a waiting writer.
  void _moveFlushToReadBuffer() {
    _readBuffer.writeBuffer(_flushBuffer);
    _resumeSlot('write');
  }

  /// Waits as [task], `read` or `write`, while [shouldSleep] holds.
  Future<void> _sleepWhile(String task, bool Function() shouldSleep) async {
    while (shouldSleep()) {
      await suspendCancellableCoroutine<void>((it) {
        final slot = TaskSlot(task, it);
        it.invokeOnCancellation((cause) {
          if (identical(_slot, slot)) {
            _slot = const EmptySlot();
          }
        });
        _trySuspend(slot);
      });
    }
  }

  /// Puts [slot] into the slot of the channel and fails a waiter of the
  /// same kind that waited there with a [ConcurrentIoException].
  ///
  /// The slot is never closed here and never holds the other kind: every
  /// sleep condition requires the channel to be open, a flush wakes a
  /// waiting reader before the writer waits, and nothing changes between
  /// the check and the suspension, since Dart runs them in one go.
  void _trySuspend(TaskSlot slot) {
    final ChannelSlot previous = _slot;
    _slot = slot;
    if (previous is TaskSlot) {
      previous.resume(ConcurrentIoException(slot.task));
    }
  }

  /// Wakes the waiter in the slot if it waits as [task].
  void _resumeSlot(String task) {
    final ChannelSlot current = _slot;
    if (current is TaskSlot && current.task == task) {
      _slot = const EmptySlot();
      current.resume();
    }
  }

  /// Closes the slot with [cause], wakes whoever waited there with it and
  /// runs the close handler.
  void _closeSlot(Object? cause) {
    final ChannelSlot previous = _slot;
    _slot = ClosedSlot(cause);
    if (previous is TaskSlot) {
      previous.resume(cause);
    }
    final void Function(Object? cause)? handler = _closeHandler;
    _closeHandler = null;
    handler?.call(cause);
  }
}
