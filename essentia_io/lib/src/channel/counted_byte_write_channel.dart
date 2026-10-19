/*
 * Copyright 2026 Davils
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:essentia_io/src/buffer/buffer.dart';
import 'package:essentia_io/src/channel/byte_write_channel.dart';

/// A channel that counts the bytes written through it to [_delegate].
final class CountedByteWriteChannel implements ByteWriteChannel {
  /// Creates the channel that writes to [_delegate].
  CountedByteWriteChannel(this._delegate)
    : _initial = _delegate.isClosedForWrite ? 0 : _delegate.writeBuffer.size;

  /// The channel written to.
  final ByteWriteChannel _delegate;

  /// The bytes of the write buffer that were there before, not counted.
  int _initial;

  /// The bytes flushed through the channel.
  var _flushed = 0;

  /// The number of bytes written through the channel, flushed or not.
  int get totalBytesWritten => _flushed + writeBuffer.size - _initial;

  /// Whether [_delegate] flushes every write.
  @override
  bool get autoFlush => _delegate.autoFlush;

  /// Whether [_delegate] is closed.
  @override
  bool get isClosedForWrite => _delegate.isClosedForWrite;

  /// Why [_delegate] failed.
  @override
  Exception? get closedCause => _delegate.closedCause;

  /// The write buffer of [_delegate].
  @override
  Buffer get writeBuffer => _delegate.writeBuffer;

  /// Flushes [_delegate] and counts what it flushed.
  @override
  Future<void> flush() async {
    _flushed += writeBuffer.size - _initial;
    _initial = 0;
    await _delegate.flush();
    _initial = writeBuffer.size;
  }

  /// Flushes and closes [_delegate].
  @override
  Future<void> flushAndClose() => _delegate.flushAndClose();

  /// Cancels [_delegate] with [cause].
  @override
  void cancel([Object? cause]) {
    _delegate.cancel(cause);
  }
}
