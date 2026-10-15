/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_io/src/buffer/buffer.dart';
import 'package:essentia_io/src/channel/byte_read_channel.dart';

/// A channel that counts the bytes read through it from [delegate], Ktor's
/// `CountedByteReadChannel`.
final class CountedByteReadChannel implements ByteReadChannel {
  /// Creates the channel that reads from [delegate].
  CountedByteReadChannel(this.delegate);

  /// The channel read from.
  final ByteReadChannel delegate;

  /// The bytes taken from [delegate] and not read yet.
  final _buffer = Buffer();

  /// The size of [_buffer] when the count was last brought up to date.
  var _initial = 0;

  /// The bytes read before the count was last brought up to date.
  var _consumed = 0;

  /// The number of bytes read through the channel.
  int get totalBytesRead {
    _updateConsumed();
    return _consumed;
  }

  /// Why [delegate] failed.
  @override
  Exception? get closedCause => delegate.closedCause;

  /// Whether every byte is read and [delegate] ended.
  @override
  bool get isClosedForRead => _buffer.exhausted && delegate.isClosedForRead;

  /// The bytes not read yet, topped up from [delegate].
  @override
  Buffer get readBuffer {
    _transferFromDelegate();
    return _buffer;
  }

  /// Waits until at least [min] bytes may be read.
  ///
  /// Returns `true` when they may, `false` when [delegate] ended before.
  @override
  Future<bool> awaitContent([int min = 1]) async {
    if (readBuffer.size >= min) {
      return true;
    }
    if (await delegate.awaitContent(min)) {
      _transferFromDelegate();
      return true;
    }
    return false;
  }

  /// Cancels [delegate] with [cause] and drops the bytes not read.
  @override
  void cancel([Object? cause]) {
    delegate.cancel(cause);
    _buffer.clear();
    _initial = 0;
  }

  /// Takes the bytes [delegate] has into the buffer.
  void _transferFromDelegate() {
    _updateConsumed();
    _initial += _buffer.transferFrom(delegate.readBuffer);
  }

  /// Counts the bytes read since the count was last brought up to date.
  void _updateConsumed() {
    _consumed += _initial - _buffer.size;
    _initial = _buffer.size;
  }
}
