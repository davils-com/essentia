/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// Reading the prefix codes, counts and context maps of Brotli, RFC 7932
/// sections 3, 6, 7.3 and 9.2.
@internal
library;

import 'dart:typed_data';

import 'package:essentia_compression/src/brotli/brotli_bit_reader.dart';
import 'package:essentia_compression/src/brotli/brotli_damaged.dart';
import 'package:essentia_compression/src/brotli/brotli_prefix_code.dart';
import 'package:essentia_compression/src/brotli/brotli_tables.dart';
import 'package:meta/meta.dart';

/// Reads a prefix code over an alphabet of [alphabetSize] symbols, simple
/// or complex, RFC 7932 sections 3.4 and 3.5.
///
/// Returns the code.
///
/// Throws a [FormatException] for a code that is not valid.
@internal
BrotliPrefixCode readBrotliPrefixCode(
  BrotliBitReader reader,
  int alphabetSize,
) {
  final int skip = reader.readBits(2);
  if (skip == 1) {
    return _readSimple(reader, alphabetSize);
  }
  final lengthLengths = Uint8List(18);
  var space = 32;
  var codes = 0;
  var single = 0;
  for (var index = skip; index < 18 && space > 0; index += 1) {
    final int symbol = brotliCodeLengthOrder[index];
    final int bits = reader.peekBits(4);
    reader.skipBits(brotliCodeLengthPrefixBits[bits]);
    final int length = brotliCodeLengthPrefixValue[bits];
    lengthLengths[symbol] = length;
    if (length != 0) {
      space -= 32 >> length;
      codes += 1;
      single = symbol;
    }
  }
  if (codes != 1 && space != 0) {
    brotliDamaged('a code length code is not complete');
  }
  final lengthCode = codes == 1
      ? BrotliPrefixCode.single(single)
      : BrotliPrefixCode.fromLengths(lengthLengths);
  return BrotliPrefixCode.fromLengths(
    _readLengths(reader, lengthCode, alphabetSize),
  );
}

/// Reads a count of block types or prefix trees, 1 to 256, RFC 7932
/// section 9.2.
///
/// Returns it.
@internal
int readBrotliCount(BrotliBitReader reader) {
  if (reader.readBits(1) == 0) {
    return 1;
  }
  final int bits = reader.readBits(3);
  if (bits == 0) {
    return 2;
  }
  return (1 << bits) + 1 + reader.readBits(bits);
}

/// Reads a block count with [code], RFC 7932 section 6.
///
/// Returns it.
@internal
int readBrotliBlockCount(BrotliBitReader reader, BrotliPrefixCode code) {
  final int symbol = code.read(reader);
  return brotliBlockCountBase[symbol] +
      reader.readBits(brotliBlockCountExtra[symbol]);
}

/// Reads a context map of [size] entries over [trees] prefix trees, RFC
/// 7932 section 7.3.
///
/// Returns the map.
///
/// Throws a [FormatException] for a map that is not valid.
@internal
Uint8List readBrotliContextMap(BrotliBitReader reader, int size, int trees) {
  final int runLengthMax = reader.readBits(1) == 1 ? reader.readBits(4) + 1 : 0;
  final BrotliPrefixCode code = readBrotliPrefixCode(
    reader,
    trees + runLengthMax,
  );
  final map = Uint8List(size);
  var index = 0;
  while (index < size) {
    final int symbol = code.read(reader);
    if (symbol == 0) {
      index += 1;
      continue;
    }
    if (symbol <= runLengthMax) {
      final int zeros = (1 << symbol) + reader.readBits(symbol);
      if (index + zeros > size) {
        brotliDamaged('a run of zeros overflows a context map');
      }
      index += zeros;
      continue;
    }
    map[index] = symbol - runLengthMax;
    index += 1;
  }
  if (reader.readBits(1) == 1) {
    _inverseMoveToFront(map);
  }
  return map;
}

/// Reads a simple prefix code over [alphabetSize] symbols, RFC 7932
/// section 3.4.
///
/// Returns the code.
///
/// Throws a [FormatException] for a symbol out of the alphabet or one
/// given twice.
BrotliPrefixCode _readSimple(BrotliBitReader reader, int alphabetSize) {
  final int count = reader.readBits(2) + 1;
  final int bits = (alphabetSize - 1).bitLength;
  final symbols = <int>[];
  for (var index = 0; index < count; index += 1) {
    final int symbol = reader.readBits(bits);
    if (symbol >= alphabetSize || symbols.contains(symbol)) {
      brotliDamaged('a simple prefix code repeats or exceeds its symbols');
    }
    symbols.add(symbol);
  }
  if (count == 1) {
    return BrotliPrefixCode.single(symbols.first);
  }
  final lengths = count == 2
      ? const <int>[1, 1]
      : count == 3
      ? const <int>[1, 2, 2]
      : reader.readBits(1) == 0
      ? const <int>[2, 2, 2, 2]
      : const <int>[1, 2, 3, 3];
  final codeLengths = Uint8List(alphabetSize);
  for (var index = 0; index < count; index += 1) {
    codeLengths[symbols[index]] = lengths[index];
  }
  return BrotliPrefixCode.fromLengths(codeLengths);
}

/// Reads the code lengths of the [alphabetSize] symbols of a complex
/// prefix code with [lengthCode], RFC 7932 section 3.5.
///
/// Returns them.
///
/// Throws a [FormatException] for lengths that overflow the alphabet or do
/// not make a complete code.
Uint8List _readLengths(
  BrotliBitReader reader,
  BrotliPrefixCode lengthCode,
  int alphabetSize,
) {
  final lengths = Uint8List(alphabetSize);
  var symbol = 0;
  var previous = 8;
  var repeat = 0;
  var repeatLength = 0;
  var space = 32768;
  while (symbol < alphabetSize && space > 0) {
    final int code = lengthCode.read(reader);
    if (code < 16) {
      repeat = 0;
      lengths[symbol] = code;
      symbol += 1;
      if (code != 0) {
        previous = code;
        space -= 32768 >> code;
      }
      continue;
    }
    final extra = code == 16 ? 2 : 3;
    final length = code == 16 ? previous : 0;
    if (repeatLength != length) {
      repeat = 0;
      repeatLength = length;
    }
    final before = repeat;
    if (repeat > 0) {
      repeat = (repeat - 2) << extra;
    }
    repeat += reader.readBits(extra) + 3;
    final int added = repeat - before;
    if (symbol + added > alphabetSize) {
      brotliDamaged('repeated code lengths overflow the alphabet');
    }
    lengths.fillRange(symbol, symbol + added, repeatLength);
    symbol += added;
    if (repeatLength != 0) {
      space -= added << (15 - repeatLength);
    }
  }
  if (space != 0) {
    brotliDamaged('a prefix code is not complete');
  }
  return lengths;
}

/// Undoes the move-to-front transform of [map], RFC 7932 section 7.3.
void _inverseMoveToFront(Uint8List map) {
  final order = Uint8List.fromList(<int>[for (var i = 0; i < 256; i += 1) i]);
  for (var index = 0; index < map.length; index += 1) {
    int position = map[index];
    final int value = order[position];
    map[index] = value;
    while (position > 0) {
      order[position] = order[position - 1];
      position -= 1;
    }
    order[0] = value;
  }
}
