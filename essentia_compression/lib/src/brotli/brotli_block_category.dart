/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_compression/src/brotli/brotli_bit_reader.dart';
import 'package:essentia_compression/src/brotli/brotli_codes.dart';
import 'package:essentia_compression/src/brotli/brotli_prefix_code.dart';
import 'package:meta/meta.dart';

/// The blocks of one category of a meta-block, literals, insert-and-copy
/// lengths or distances, RFC 7932 section 6: how many types there are, the
/// current and the previous type, and how many symbols the current block
/// has left.
@internal
final class BrotliBlockCategory {
  /// Creates the category of [count] types, switched with [_types] and
  /// [_counts], whose first block holds [remaining] symbols.
  BrotliBlockCategory._(this.count, this._types, this._counts, this.remaining);

  /// Reads the category from a meta-block header.
  ///
  /// Returns it.
  factory BrotliBlockCategory.read(BrotliBitReader reader) {
    final int count = readBrotliCount(reader);
    if (count < 2) {
      return BrotliBlockCategory._(count, null, null, _unlimited);
    }
    final BrotliPrefixCode types = readBrotliPrefixCode(reader, count + 2);
    final BrotliPrefixCode counts = readBrotliPrefixCode(reader, 26);
    return BrotliBlockCategory._(
      count,
      types,
      counts,
      readBrotliBlockCount(reader, counts),
    );
  }

  /// The symbols a block of the only type holds: more than a meta-block.
  static const int _unlimited = 1 << 30;

  /// How many block types there are.
  final int count;

  /// The code of block types, `null` for one type.
  final BrotliPrefixCode? _types;

  /// The code of block counts, `null` for one type.
  final BrotliPrefixCode? _counts;

  /// The current block type.
  var type = 0;

  /// The block type before the current one.
  var _previous = 1;

  /// How many symbols the current block has left.
  int remaining;

  /// [type] as [save] kept it.
  var _savedType = 0;

  /// [_previous] as [save] kept it.
  var _savedPrevious = 1;

  /// [remaining] as [save] kept it.
  var _savedRemaining = 0;

  /// Counts the next symbol of the category, switching to the next block
  /// first when the current one has none left.
  void next(BrotliBitReader reader) {
    if (remaining == 0) {
      _switch(reader);
    }
    remaining -= 1;
  }

  /// Keeps the state, for [restore].
  void save() {
    _savedType = type;
    _savedPrevious = _previous;
    _savedRemaining = remaining;
  }

  /// Goes back to the state [save] kept.
  void restore() {
    type = _savedType;
    _previous = _savedPrevious;
    remaining = _savedRemaining;
  }

  /// Reads a block switch command, RFC 7932 section 6.
  void _switch(BrotliBitReader reader) {
    final int symbol = _types!.read(reader);
    int next = symbol == 0 ? _previous : symbol - 2;
    if (symbol == 1) {
      next = type + 1 == count ? 0 : type + 1;
    }
    _previous = type;
    type = next;
    remaining = readBrotliBlockCount(reader, _counts!);
  }
}
