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

import 'dart:typed_data';

/// Writes the bits of a Brotli stream by hand, least significant bit of
/// each byte first, for streams no encoder writes: damaged ones, and ones
/// that reach a corner of the format.
final class BrotliBitWriter {
  /// The bytes written.
  final _bytes = <int>[];

  /// The bits of the byte being written.
  var _current = 0;

  /// How many bits [_current] holds.
  var _count = 0;

  /// Writes the [count] low bits of [value], the lowest first.
  void bits(int value, int count) {
    for (var bit = 0; bit < count; bit += 1) {
      _current |= ((value >> bit) & 1) << _count;
      _count += 1;
      if (_count == 8) {
        _flush();
      }
    }
  }

  /// Writes the prefix code [code] of [length] bits, its highest bit
  /// first, as RFC 7932 stores prefix codes.
  void code(int code, int length) {
    for (int bit = length - 1; bit >= 0; bit -= 1) {
      bits(code >> bit, 1);
    }
  }

  /// Fills the byte being written with zero bits.
  void align() {
    if (_count > 0) {
      _flush();
    }
  }

  /// Writes [bytes] whole, after the bits up to the byte boundary.
  void bytes(List<int> bytes) {
    align();
    _bytes.addAll(bytes);
  }

  /// The stream written, its last byte filled with zero bits.
  ///
  /// Returns the bytes.
  Uint8List done() {
    align();
    return Uint8List.fromList(_bytes);
  }

  /// Ends the byte being written.
  void _flush() {
    _bytes.add(_current);
    _current = 0;
    _count = 0;
  }
}
