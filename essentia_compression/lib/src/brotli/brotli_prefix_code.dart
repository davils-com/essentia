/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:typed_data';

import 'package:essentia_compression/src/brotli/brotli_bit_reader.dart';
import 'package:meta/meta.dart';

/// A canonical prefix code of Brotli, RFC 7932 section 3.2, as a table of
/// two levels: the first eight bits of a code look up its symbol, or the
/// table of the bits that follow.
///
/// An entry holds the symbol, or the offset of a second level table, in
/// its low 16 bits, the length of the code, or the bits of the second
/// level table, in the four above, and above them whether it points at a
/// second level table.
@internal
final class BrotliPrefixCode {
  /// Creates the code of [_table].
  BrotliPrefixCode._(this._table);

  /// Creates the code of one [symbol], read with no bits at all.
  factory BrotliPrefixCode.single(int symbol) =>
      BrotliPrefixCode._(Int32List(_rootSize)..fillRange(0, _rootSize, symbol));

  /// Creates the canonical code of the code [lengths] of the symbols, 0
  /// for a symbol not coded; the lengths make a complete code.
  factory BrotliPrefixCode.fromLengths(List<int> lengths) {
    final counts = Int32List(_maxLength + 1);
    for (final length in lengths) {
      counts[length] += 1;
    }
    counts[0] = 0;
    final next = Int32List(_maxLength + 2);
    var code = 0;
    for (var length = 1; length <= _maxLength; length += 1) {
      code = (code + counts[length - 1]) << 1;
      next[length] = code;
    }
    final reversed = Int32List(lengths.length);
    final subBits = Int32List(_rootSize);
    for (var symbol = 0; symbol < lengths.length; symbol += 1) {
      final int length = lengths[symbol];
      if (length == 0) {
        continue;
      }
      reversed[symbol] = _reverse(next[length], length);
      next[length] += 1;
      if (length > _rootBits) {
        final int root = reversed[symbol] & (_rootSize - 1);
        if (length - _rootBits > subBits[root]) {
          subBits[root] = length - _rootBits;
        }
      }
    }
    final offsets = Int32List(_rootSize);
    int size = _rootSize;
    for (var root = 0; root < _rootSize; root += 1) {
      if (subBits[root] > 0) {
        offsets[root] = size;
        size += 1 << subBits[root];
      }
    }
    final table = Int32List(size);
    for (var root = 0; root < _rootSize; root += 1) {
      if (subBits[root] > 0) {
        table[root] = _pointer | (subBits[root] << 16) | offsets[root];
      }
    }
    for (var symbol = 0; symbol < lengths.length; symbol += 1) {
      final int length = lengths[symbol];
      if (length == 0) {
        continue;
      }
      final int entry = (length << 16) | symbol;
      if (length <= _rootBits) {
        for (
          int index = reversed[symbol];
          index < _rootSize;
          index += 1 << length
        ) {
          table[index] = entry;
        }
        continue;
      }
      final int root = reversed[symbol] & (_rootSize - 1);
      for (
        int index = reversed[symbol] >> _rootBits;
        index < 1 << subBits[root];
        index += 1 << (length - _rootBits)
      ) {
        table[offsets[root] + index] = entry;
      }
    }
    return BrotliPrefixCode._(table);
  }

  /// The longest code.
  static const _maxLength = 15;

  /// The bits the first level looks up.
  static const _rootBits = 8;

  /// The entries of the first level.
  static const int _rootSize = 1 << _rootBits;

  /// The mark of an entry that points at a second level table.
  static const int _pointer = 1 << 20;

  /// The entries.
  final Int32List _table;

  /// Reads the next symbol from [reader].
  ///
  /// Returns it.
  int read(BrotliBitReader reader) {
    final int bits = reader.peekBits(_maxLength);
    final int entry = _table[bits & (_rootSize - 1)];
    if (entry & _pointer == 0) {
      reader.skipBits(entry >> 16);
      return entry & 0xFFFF;
    }
    final int sub =
        _table[(entry & 0xFFFF) +
            ((bits >> _rootBits) & ((1 << ((entry >> 16) & 0xF)) - 1))];
    reader.skipBits(sub >> 16);
    return sub & 0xFFFF;
  }

  /// The [length] low bits of [code] in reverse order.
  ///
  /// Returns them.
  static int _reverse(int code, int length) {
    var reversed = 0;
    for (var bit = 0; bit < length; bit += 1) {
      reversed = (reversed << 1) | ((code >> bit) & 1);
    }
    return reversed;
  }
}
