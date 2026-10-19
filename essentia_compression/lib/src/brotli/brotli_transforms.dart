/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// The 121 word transformations of Brotli, RFC 7932 Appendix B.
@internal
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';

/// The number of transformations.
const brotliTransformCount = 121;

/// The elementary transform of a transformation that leaves the word
/// alone.
const brotliIdentity = 0;

/// The elementary transform that turns the first character upper case.
const brotliFermentFirst = 1;

/// The elementary transform that turns every character upper case.
const brotliFermentAll = 2;

/// The elementary transform `OmitFirst1`; `OmitFirstk` is this plus `k - 1`.
const brotliOmitFirst = 3;

/// The elementary transform `OmitLast1`; `OmitLastk` is this plus `k - 1`.
const brotliOmitLast = 12;

/// What each transformation puts before the word.
const brotliTransformPrefixes = <String>[
  '',
  '',
  ' ',
  '',
  '',
  '',
  ' ',
  's ',
  '',
  '',
  '',
  '',
  '',
  ', ',
  '',
  ' ',
  '',
  '',
  'e ',
  '',
  '',
  '',
  '',
  '',
  '',
  '',
  '',
  '',
  '',
  '',
  ' ',
  '',
  '.',
  ' ',
  '',
  '',
  '',
  '',
  '',
  '',
  '',
  ' the ',
  '',
  '',
  '',
  '',
  '',
  '',
  '',
  '',
  '',
  '',
  ' ',
  '',
  '',
  '',
  '',
  '',
  '',
  '',
  '',
  '',
  ' the ',
  '',
  '',
  ' ',
  '',
  '.',
  '',
  '',
  '',
  ' ',
  '.com/',
  ' the ',
  '',
  '',
  '',
  '.',
  '',
  '',
  '',
  ' ',
  '',
  ' ',
  '',
  ' ',
  '',
  '',
  '',
  ' ',
  '',
  ' ',
  '',
  '',
  '',
  '',
  ' ',
  '',
  ' ',
  '',
  '',
  '',
  '\u00a0',
  ' ',
  '',
  '',
  '',
  '',
  '',
  ' ',
  ' ',
  ' ',
  '',
  '',
  '',
  ' ',
  '',
  ' ',
  ' ',
  ' ',
  ' ',
];

/// The elementary transform of each transformation.
const brotliTransformTypes = <int>[
  0,
  0,
  0,
  3,
  1,
  0,
  0,
  0,
  0,
  1,
  0,
  4,
  12,
  0,
  0,
  1,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  14,
  0,
  0,
  5,
  13,
  0,
  0,
  1,
  0,
  0,
  0,
  6,
  0,
  0,
  0,
  0,
  7,
  8,
  0,
  15,
  0,
  2,
  0,
  0,
  0,
  18,
  12,
  0,
  0,
  0,
  0,
  11,
  9,
  17,
  0,
  1,
  19,
  0,
  0,
  0,
  16,
  20,
  1,
  1,
  0,
  2,
  1,
  0,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  1,
  1,
  0,
  0,
  0,
  2,
  0,
  2,
  0,
  2,
  1,
  0,
  0,
  1,
  0,
  0,
  2,
  0,
  1,
  2,
  0,
  1,
  0,
  2,
  0,
  0,
  1,
  2,
  0,
  2,
  1,
  1,
  2,
  2,
  2,
  2,
  2,
  2,
  2,
  2,
  1,
  2,
  1,
];

/// What each transformation puts after the word.
const brotliTransformSuffixes = <String>[
  '',
  ' ',
  ' ',
  '',
  ' ',
  ' the ',
  '',
  ' ',
  ' of ',
  '',
  ' and ',
  '',
  '',
  ' ',
  ', ',
  ' ',
  ' in ',
  ' to ',
  ' ',
  '"',
  '.',
  '">',
  '\n',
  '',
  ']',
  ' for ',
  '',
  '',
  ' a ',
  ' that ',
  '',
  '. ',
  '',
  ', ',
  '',
  ' with ',
  "'",
  ' from ',
  ' by ',
  '',
  '',
  '',
  '',
  '. The ',
  '',
  ' on ',
  ' as ',
  ' is ',
  '',
  'ing ',
  '\n\t',
  ':',
  '. ',
  'ed ',
  '',
  '',
  '',
  '(',
  ', ',
  '',
  ' at ',
  'ly ',
  ' of ',
  '',
  '',
  ', ',
  '"',
  '(',
  ' ',
  '">',
  '="',
  '.',
  '',
  ' of the ',
  "'",
  '. This ',
  ',',
  ' ',
  '(',
  '.',
  ' not ',
  '="',
  'er ',
  ' ',
  'al ',
  '',
  "='",
  '"',
  '. ',
  '(',
  'ful ',
  '. ',
  'ive ',
  'less ',
  "'",
  'est ',
  '.',
  '">',
  "='",
  ',',
  'ize ',
  '.',
  '',
  ',',
  '="',
  '="',
  'ous ',
  ', ',
  "='",
  ',',
  '="',
  ', ',
  ',',
  '(',
  '. ',
  '.',
  "='",
  '. ',
  '="',
  "='",
  "='",
];

/// The bytes of [brotliTransformPrefixes].
final _prefixBytes = <Uint8List>[
  for (final String prefix in brotliTransformPrefixes) utf8.encode(prefix),
];

/// The bytes of [brotliTransformSuffixes].
final _suffixBytes = <Uint8List>[
  for (final String suffix in brotliTransformSuffixes) utf8.encode(suffix),
];

/// The word of [length] bytes at [offset] of [dictionary] as
/// transformation [transform] turns it, RFC 7932 section 8.
///
/// Returns the bytes, at most 38.
Uint8List brotliTransformWord(
  Uint8List dictionary,
  int offset,
  int length,
  int transform,
) {
  final Uint8List prefix = _prefixBytes[transform];
  final Uint8List suffix = _suffixBytes[transform];
  final int type = brotliTransformTypes[transform];
  var start = offset;
  int end = offset + length;
  if (type >= brotliOmitLast) {
    end -= _omitted(type - brotliOmitLast + 1, length);
  }
  if (type >= brotliOmitFirst && type < brotliOmitLast) {
    start += _omitted(type - brotliOmitFirst + 1, length);
  }
  final int wordLength = end - start;
  final int total = prefix.length + wordLength + suffix.length;
  final word = Uint8List(total)
    ..setRange(0, prefix.length, prefix)
    ..setRange(prefix.length, prefix.length + wordLength, dictionary, start)
    ..setRange(prefix.length + wordLength, total, suffix);
  if (type == brotliFermentFirst && wordLength > 0) {
    _ferment(word, prefix.length, prefix.length + wordLength);
  }
  if (type == brotliFermentAll) {
    int position = prefix.length;
    while (position < prefix.length + wordLength) {
      position += _ferment(word, position, prefix.length + wordLength);
    }
  }
  return word;
}

/// How many of the [length] bytes of a word omitting [count] drops: all of
/// them when the word is shorter.
///
/// Returns it.
int _omitted(int count, int length) => count > length ? length : count;

/// Turns the character at [position] of [word], which ends at [end], upper
/// case as RFC 7932 section 8 defines it.
///
/// Returns the length of the character, 1 to 3 bytes.
int _ferment(Uint8List word, int position, int end) {
  final int byte = word[position];
  if (byte < 192) {
    if (byte >= 97 && byte <= 122) {
      word[position] = byte ^ 32;
    }
    return 1;
  }
  if (byte < 224) {
    if (position + 1 < end) {
      word[position + 1] ^= 32;
    }
    return 2;
  }
  if (position + 2 < end) {
    word[position + 2] ^= 5;
  }
  return 3;
}
