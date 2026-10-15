/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/charset/internal/string_encoding.dart';
import 'package:meta/meta.dart';

/// Encodes UTF-16, RFC 2781, a code unit to two bytes; an unpaired
/// surrogate encodes as U+FFFD, so that the bytes are always well formed.
@internal
final class Utf16Encoding implements StringEncoding {
  /// Creates the encoding of UTF-16 that writes the big-endian byte order
  /// mark before the first character, as Java does.
  Utf16Encoding.marked() : _bigEndian = true, _markPending = true;

  /// Creates the encoding of big-endian UTF-16 without a mark.
  Utf16Encoding.bigEndian() : _bigEndian = true, _markPending = false;

  /// Creates the encoding of little-endian UTF-16 without a mark.
  Utf16Encoding.littleEndian() : _bigEndian = false, _markPending = false;

  /// Whether the more significant byte of a code unit comes first.
  final bool _bigEndian;

  /// Whether the byte order mark is still to be written.
  bool _markPending;

  /// A high surrogate whose low surrogate may come with the next chunk.
  int? _pendingHigh;

  /// Encodes the code units of [chunk] from [start] to [end].
  ///
  /// Returns the bytes.
  @override
  List<int> add(String chunk, int start, int end) {
    final units = <int>[];
    for (var index = start; index < end; index++) {
      _unit(chunk.codeUnitAt(index), units);
    }
    return _bytes(units);
  }

  /// Ends the encoding.
  ///
  /// Returns the bytes of a replacement character for a high surrogate
  /// left unpaired, no bytes without one.
  @override
  List<int> close() {
    if (_pendingHigh == null) {
      return const <int>[];
    }
    _pendingHigh = null;
    return _bytes(<int>[0xFFFD]);
  }

  /// Encodes the code [unit] into [units].
  void _unit(int unit, List<int> units) {
    final int? high = _pendingHigh;
    if (high != null) {
      _pendingHigh = null;
      if (unit >= 0xDC00 && unit <= 0xDFFF) {
        units
          ..add(high)
          ..add(unit);
        return;
      }
      units.add(0xFFFD);
    }
    if (unit >= 0xD800 && unit <= 0xDBFF) {
      _pendingHigh = unit;
      return;
    }
    units.add(unit >= 0xDC00 && unit <= 0xDFFF ? 0xFFFD : unit);
  }

  /// Writes [units] as bytes, after the mark if it is still to be written.
  ///
  /// Returns the bytes.
  List<int> _bytes(List<int> units) {
    if (units.isEmpty) {
      return const <int>[];
    }
    final bytes = <int>[];
    if (_markPending) {
      _markPending = false;
      bytes.addAll(const <int>[0xFE, 0xFF]);
    }
    for (final unit in units) {
      if (_bigEndian) {
        bytes
          ..add(unit >> 8)
          ..add(unit & 0xFF);
        continue;
      }
      bytes
        ..add(unit & 0xFF)
        ..add(unit >> 8);
    }
    return bytes;
  }
}
