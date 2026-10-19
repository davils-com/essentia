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

import 'dart:math' as math;

import 'package:essentia_io/src/buffer/buffer.dart';
import 'package:essentia_io/src/channel/byte_read_channel.dart';
import 'package:essentia_io/src/exception/eof_exception.dart';
import 'package:essentia_io/src/exception/too_long_line_exception.dart';
import 'package:meta/meta.dart';

/// The byte of a carriage return.
const _cr = 0x0D;

/// The byte of a line feed.
const _lf = 0x0A;

/// A limit that is no limit, the largest integer exact on every platform.
@internal
const unlimitedLine = 0x1FFFFFFFFFFFFF;

/// Reads one line of UTF-8 from a channel.
@internal
final class LineReader {
  /// Creates the reader of a line of [_channel] into [_out], of at most
  /// [_limit] bytes; [lenient] also ends a line at a CR alone, and
  /// [strict] refuses a last line without an ending.
  LineReader(
    this._channel,
    this._out,
    this._limit, {
    required this.lenient,
    required this.strict,
  }) : _readBuffer = _channel.readBuffer;

  /// The channel the line is read from.
  final ByteReadChannel _channel;

  /// Where the line goes.
  final StringSink _out;

  /// The most bytes the line may have.
  final int _limit;

  /// Whether a CR alone ends a line.
  final bool lenient;

  /// Whether a last line without an ending fails.
  final bool strict;

  /// The bytes of the channel.
  final Buffer _readBuffer;

  /// The bytes of the line read so far, where the line spans more than
  /// what has arrived; `null` while the line is decoded at once.
  Buffer? _pending;

  /// The bytes of the line taken so far.
  var _consumed = 0;

  /// Reads the line.
  ///
  /// Returns the number of its bytes without the ending, or -1 when the
  /// channel ended before any byte.
  ///
  /// Throws a [TooLongLineException] for a line longer than the limit and,
  /// when strict, an [EofException] for a last line without an ending.
  Future<int> read() async {
    if (_readBuffer.exhausted) {
      await _channel.awaitContent();
    }
    if (_channel.isClosedForRead) {
      return -1;
    }
    try {
      return await _scan();
    } finally {
      final Buffer? pending = _pending;
      if (pending != null) {
        _out.write(pending.readString());
      }
    }
  }

  /// Takes the bytes of the line until its ending, the limit or the end.
  ///
  /// Returns the number of bytes of the line.
  Future<int> _scan() async {
    while (_consumed < _limit && !_channel.isClosedForRead) {
      final int limitLeft = _limit - _consumed;
      final int lfIndex = _readBuffer.indexOf(
        _lf,
        0,
        math.min(limitLeft, _readBuffer.size),
      );
      final int crIndex = _soleCr(lfIndex, limitLeft);
      if (crIndex >= 0) {
        _appendOrBuffer(crIndex);
        _readBuffer.discard(1);
        return _consumed;
      }
      if (lfIndex == 0) {
        _readBuffer.discard(1);
        return _consumed;
      }
      if (lfIndex > 0) {
        final crlf = _readBuffer[lfIndex - 1] == _cr ? 1 : 0;
        _appendOrBuffer(lfIndex - crlf);
        _readBuffer.discard(1 + crlf);
        return _consumed;
      }
      final int count = math.min(limitLeft, _readBuffer.size);
      final endsWithCr = _readBuffer[count - 1] == _cr;
      if (endsWithCr) {
        _appendOrBuffer(count - 1);
        if (await _discardCrlfOrCr()) {
          return _consumed;
        }
        _bufferBytes(1);
      }
      if (!endsWithCr) {
        _bufferBytes(count);
      }
      if (_consumed < _limit &&
          _readBuffer.exhausted &&
          !await _channel.awaitContent()) {
        break;
      }
    }
    if (_consumed == _limit) {
      return _atLimit();
    }
    if (strict) {
      throw EofException(
        'Unexpected end of stream after reading $_consumed bytes',
      );
    }
    return _consumed;
  }

  /// Decides a line that reached the limit: it ends there when its ending
  /// follows right away.
  ///
  /// Returns the number of bytes of the line.
  ///
  /// Throws a [TooLongLineException] when no ending follows, and an
  /// [EofException] when the channel ends there.
  Future<int> _atLimit() async {
    if (_limit == unlimitedLine) {
      throw const TooLongLineException('Max line length exceeded');
    }
    if (_readBuffer.exhausted && !await _channel.awaitContent()) {
      throw EofException(
        'Unexpected end of stream after reading $_consumed bytes',
      );
    }
    final int next = _readBuffer[0];
    if (next == _lf) {
      _readBuffer.discard(1);
      return _consumed;
    }
    if (next == _cr && await _discardCrlfOrCr()) {
      return _consumed;
    }
    throw TooLongLineException('Line exceeds limit of $_limit bytes');
  }

  /// The position of a CR that ends the line on its own, in lenient mode,
  /// before [lfIndex] or, without a line feed, before the last byte, which
  /// may be the CR of a CR LF split by the arrival.
  ///
  /// Returns it, or -1.
  int _soleCr(int lfIndex, int limitLeft) {
    if (!lenient) {
      return -1;
    }
    final int end = switch (lfIndex) {
      -1 => math.min(limitLeft, _readBuffer.size - 1),
      0 => 0,
      final int index => index - 1,
    };
    return _readBuffer.indexOf(_cr, 0, end);
  }

  /// Drops the CR at the front and the LF behind it, or in lenient mode the
  /// CR alone.
  ///
  /// Returns whether an ending was dropped.
  Future<bool> _discardCrlfOrCr() async {
    final bool two = _readBuffer.size >= 2 || await _channel.awaitContent(2);
    if (two && _readBuffer[1] == _lf) {
      _readBuffer.discard(2);
      return true;
    }
    if (lenient) {
      _readBuffer.discard(1);
      return true;
    }
    return false;
  }

  /// Keeps [count] bytes of the line aside, to be decoded with the rest.
  void _bufferBytes(int count) {
    if (count <= 0) {
      return;
    }
    (_pending ??= Buffer()).writeBuffer(_readBuffer, count);
    _consumed += count;
  }

  /// Decodes [count] bytes of the line into the output, or keeps them aside
  /// once part of the line is kept.
  void _appendOrBuffer(int count) {
    if (_pending != null) {
      _bufferBytes(count);
      return;
    }
    if (count > 0) {
      _out.write(_readBuffer.readString(count: count));
      _consumed += count;
    }
  }
}
