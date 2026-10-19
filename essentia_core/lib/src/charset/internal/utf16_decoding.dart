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

import 'package:essentia_core/src/charset/internal/byte_decoding.dart';
import 'package:meta/meta.dart';

/// Decodes UTF-16, RFC 2781, two bytes to a code unit; an unpaired
/// surrogate and a lone last byte decode to U+FFFD.
@internal
final class Utf16Decoding implements ByteDecoding {
  /// Creates the decoding of UTF-16 with a byte order mark: the mark is
  /// skipped and decides the order, big-endian without one.
  Utf16Decoding.marked() : _bigEndian = true, _detecting = true;

  /// Creates the decoding of big-endian UTF-16 without a mark.
  Utf16Decoding.bigEndian() : _bigEndian = true, _detecting = false;

  /// Creates the decoding of little-endian UTF-16 without a mark.
  Utf16Decoding.littleEndian() : _bigEndian = false, _detecting = false;

  /// Whether the more significant byte of a code unit comes first.
  bool _bigEndian;

  /// Whether the first code unit may still be a byte order mark.
  bool _detecting;

  /// The first byte of a code unit whose second byte has not come yet.
  int? _pendingByte;

  /// A high surrogate whose low surrogate has not come yet.
  int? _pendingHigh;

  /// Decodes the bytes of [chunk] from [start] to [end].
  ///
  /// Returns the text they complete.
  @override
  String add(List<int> chunk, int start, int end) {
    final codes = <int>[];
    for (var index = start; index < end; index++) {
      final int byte = chunk[index] & 0xFF;
      final int? first = _pendingByte;
      if (first == null) {
        _pendingByte = byte;
        continue;
      }
      _pendingByte = null;
      _unit(_bigEndian ? first << 8 | byte : byte << 8 | first, codes);
    }
    return String.fromCharCodes(codes);
  }

  /// Ends the decoding.
  ///
  /// Returns a replacement character for each incomplete code unit or
  /// pair, the empty text without one.
  @override
  String close() {
    final codes = <int>[
      if (_pendingHigh != null) 0xFFFD,
      if (_pendingByte != null) 0xFFFD,
    ];
    _pendingHigh = null;
    _pendingByte = null;
    return String.fromCharCodes(codes);
  }

  /// Decodes the code [unit] into [codes].
  void _unit(int unit, List<int> codes) {
    if (_detecting) {
      _detecting = false;
      if (unit == 0xFEFF) {
        return;
      }
      if (unit == 0xFFFE) {
        _bigEndian = false;
        return;
      }
    }
    final int? high = _pendingHigh;
    if (high != null) {
      _pendingHigh = null;
      if (_isLow(unit)) {
        codes.add(0x10000 + ((high - 0xD800) << 10) + (unit - 0xDC00));
        return;
      }
      codes.add(0xFFFD);
    }
    if (_isHigh(unit)) {
      _pendingHigh = unit;
      return;
    }
    codes.add(_isLow(unit) ? 0xFFFD : unit);
  }

  /// Whether [unit] is a high surrogate.
  ///
  /// Returns `true` when it is.
  static bool _isHigh(int unit) => unit >= 0xD800 && unit <= 0xDBFF;

  /// Whether [unit] is a low surrogate.
  ///
  /// Returns `true` when it is.
  static bool _isLow(int unit) => unit >= 0xDC00 && unit <= 0xDFFF;
}
