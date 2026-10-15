/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:typed_data';

import 'package:essentia_core/src/bytes/compression/brotli/brotli_bit_mark.dart';
import 'package:essentia_core/src/bytes/compression/brotli/brotli_input_needed.dart';
import 'package:meta/meta.dart';

/// Reads the bits of Brotli data, least significant bit of each byte
/// first, from the bytes added to it, RFC 7932 section 1.5.
///
/// A read that needs more bytes than were added throws
/// [brotliInputNeeded] while more may come, and a [FormatException] once
/// [close] said none will. At most 31 bits are loaded at a time, which
/// keeps every value an unsigned 32-bit integer on the web too.
@internal
final class BrotliBitReader {
  /// The bytes added and not yet dropped.
  var _buffer = Uint8List(0);

  /// How many bytes of [_buffer] hold data.
  var _end = 0;

  /// The next byte of [_buffer] to load.
  var _position = 0;

  /// The loaded bits not read yet, the next one lowest.
  var _bits = 0;

  /// How many bits [_bits] holds.
  var _bitCount = 0;

  /// Whether no more bytes come.
  var _closed = false;

  /// Whether any byte is left, loaded and unread or not loaded.
  bool get hasData => _bitCount >= 8 || _position < _end;

  /// Adds [bytes] behind those added before, dropping the bytes already
  /// loaded.
  void add(List<int> bytes) {
    final int kept = _end - _position;
    final int total = kept + bytes.length;
    _buffer = (_buffer.length < total ? Uint8List(total) : _buffer)
      ..setRange(0, kept, _buffer, _position)
      ..setRange(kept, total, bytes);
    _end = total;
    _position = 0;
  }

  /// Says that no more bytes come.
  void close() {
    _closed = true;
  }

  /// Where the reader stands.
  ///
  /// Returns the mark to go back to with [reset].
  BrotliBitMark mark() =>
      (position: _position, bits: _bits, bitCount: _bitCount);

  /// Goes back to [mark].
  void reset(BrotliBitMark mark) {
    _position = mark.position;
    _bits = mark.bits;
    _bitCount = mark.bitCount;
  }

  /// Reads the next [count] bits, 0 to 24.
  ///
  /// Returns them as an unsigned integer, the first bit lowest.
  int readBits(int count) {
    if (count == 0) {
      return 0;
    }
    _fill(count);
    final int value = _bits & ((1 << count) - 1);
    _bits >>= count;
    _bitCount -= count;
    return value;
  }

  /// The next [count] bits, 1 to 15, without reading them; the bits
  /// behind the end of the bytes added are zero.
  ///
  /// Returns them, the first bit lowest.
  int peekBits(int count) {
    while (_bitCount < count && _position < _end) {
      _bits |= _buffer[_position] << _bitCount;
      _position += 1;
      _bitCount += 8;
    }
    return _bits & ((1 << count) - 1);
  }

  /// Reads the [count] bits [peekBits] returned.
  void skipBits(int count) {
    if (count > _bitCount) {
      _starved();
    }
    _bits >>= count;
    _bitCount -= count;
  }

  /// Drops the bits up to the next byte boundary, which must be zero.
  ///
  /// Throws a [FormatException] when they are not.
  void alignToByte() {
    final int padding = _bitCount & 7;
    if ((_bits & ((1 << padding) - 1)) != 0) {
      throw const FormatException(
        'The brotli data is damaged: its padding bits are not zero',
      );
    }
    _bits >>= padding;
    _bitCount -= padding;
  }

  /// How many whole bytes can be read after [alignToByte].
  int get alignedBytes => (_bitCount >> 3) + _end - _position;

  /// Reads the next byte after [alignToByte].
  ///
  /// Returns it.
  int readAlignedByte() {
    if (_bitCount >= 8) {
      return readBits(8);
    }
    if (_position == _end) {
      _starved();
    }
    final int byte = _buffer[_position];
    _position += 1;
    return byte;
  }

  /// Loads bytes until [count] bits are loaded.
  void _fill(int count) {
    while (_bitCount < count) {
      if (_position == _end) {
        _starved();
      }
      _bits |= _buffer[_position] << _bitCount;
      _position += 1;
      _bitCount += 8;
    }
  }

  /// Fails a read for want of bytes.
  ///
  /// Throws [brotliInputNeeded] while more bytes may come, a
  /// [FormatException] once none will.
  Never _starved() {
    if (_closed) {
      throw const FormatException('The brotli data is cut short');
    }
    throw brotliInputNeeded;
  }
}
