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
import 'package:essentia_io/src/channel/byte_read_channel.dart';

/// A channel that counts the bytes read through it from [delegate].
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
