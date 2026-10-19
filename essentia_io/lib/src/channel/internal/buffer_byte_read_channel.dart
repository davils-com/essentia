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
import 'package:essentia_io/src/channel/internal/close_token.dart';
import 'package:essentia_io/src/exception/io_exception.dart';
import 'package:meta/meta.dart';

/// A channel that reads the bytes of a buffer that is complete.
@internal
final class BufferByteReadChannel implements ByteReadChannel {
  /// Creates the channel of the bytes of [_source].
  BufferByteReadChannel(this._source);

  /// The bytes to read.
  final Buffer _source;

  /// How the channel was cancelled, `null` until it is.
  CloseToken? _closed;

  /// Why the channel failed, `null` until it is cancelled.
  @override
  Exception? get closedCause => _closed?.wrapCause();

  /// Whether every byte is read.
  @override
  bool get isClosedForRead => _source.exhausted;

  /// The bytes not read yet.
  ///
  /// Throws [closedCause] once the channel was cancelled.
  @override
  Buffer get readBuffer {
    _rethrowCloseCause();
    return _source;
  }

  /// Whether at least [min] bytes are left, which never changes by waiting.
  ///
  /// Returns `true` when they are.
  ///
  /// Throws [closedCause] once the channel was cancelled.
  @override
  Future<bool> awaitContent([int min = 1]) async {
    _rethrowCloseCause();
    return _source.size >= min;
  }

  /// Cancels the channel with [cause] and drops the bytes not read.
  @override
  void cancel([Object? cause]) {
    if (_closed != null) {
      return;
    }
    _source.clear();
    _closed = CloseToken(
      cause ?? const IoException('Channel was cancelled'),
      StackTrace.current,
    );
  }

  /// Throws [closedCause] once the channel was cancelled.
  void _rethrowCloseCause() {
    final Exception? cause = closedCause;
    if (cause != null) {
      throw cause;
    }
  }
}
