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

/// The fixed tables of Brotli, RFC 7932.
@internal
library;

import 'dart:typed_data';

import 'package:meta/meta.dart';

/// The order in which the code lengths of the code length alphabet are
/// stored, RFC 7932 section 3.5.
const brotliCodeLengthOrder = <int>[
  1,
  2,
  3,
  4,
  0,
  5,
  17,
  6,
  16,
  7,
  8,
  9,
  10,
  11,
  12,
  13,
  14,
  15,
];

/// The code length of a code length code, by the next four bits of the
/// stream, RFC 7932 section 3.5.
const brotliCodeLengthPrefixValue = <int>[
  0,
  4,
  3,
  2,
  0,
  4,
  3,
  1,
  0,
  4,
  3,
  2,
  0,
  4,
  3,
  5,
];

/// How many bits the code length of [brotliCodeLengthPrefixValue] takes.
const brotliCodeLengthPrefixBits = <int>[
  2,
  2,
  2,
  3,
  2,
  2,
  2,
  4,
  2,
  2,
  2,
  3,
  2,
  2,
  2,
  4,
];

/// The smallest block count of each block count code, RFC 7932 section 6.
const brotliBlockCountBase = <int>[
  1,
  5,
  9,
  13,
  17,
  25,
  33,
  41,
  49,
  65,
  81,
  97,
  113,
  145,
  177,
  209,
  241,
  305,
  369,
  497,
  753,
  1265,
  2289,
  4337,
  8433,
  16625,
];

/// The extra bits of each block count code, RFC 7932 section 6.
const brotliBlockCountExtra = <int>[
  2,
  2,
  2,
  2,
  3,
  3,
  3,
  3,
  4,
  4,
  4,
  4,
  5,
  5,
  5,
  5,
  6,
  6,
  7,
  8,
  9,
  10,
  11,
  12,
  13,
  24,
];

/// The smallest insert length of each insert length code, RFC 7932
/// section 5.
const brotliInsertBase = <int>[
  0,
  1,
  2,
  3,
  4,
  5,
  6,
  8,
  10,
  14,
  18,
  26,
  34,
  50,
  66,
  98,
  130,
  194,
  322,
  578,
  1090,
  2114,
  6210,
  22594,
];

/// The extra bits of each insert length code, RFC 7932 section 5.
const brotliInsertExtra = <int>[
  0,
  0,
  0,
  0,
  0,
  0,
  1,
  1,
  2,
  2,
  3,
  3,
  4,
  4,
  5,
  5,
  6,
  7,
  8,
  9,
  10,
  12,
  14,
  24,
];

/// The smallest copy length of each copy length code, RFC 7932 section 5.
const brotliCopyBase = <int>[
  2,
  3,
  4,
  5,
  6,
  7,
  8,
  9,
  10,
  12,
  14,
  18,
  22,
  30,
  38,
  54,
  70,
  102,
  134,
  198,
  326,
  582,
  1094,
  2118,
];

/// The extra bits of each copy length code, RFC 7932 section 5.
const brotliCopyExtra = <int>[
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  1,
  1,
  2,
  2,
  3,
  3,
  4,
  4,
  5,
  5,
  6,
  7,
  8,
  9,
  10,
  24,
];

/// The first insert length code of each cell of 64 insert-and-copy length
/// codes, RFC 7932 section 5.
const brotliCellInsert = <int>[0, 0, 0, 0, 8, 8, 0, 16, 8, 16, 16];

/// The first copy length code of each cell of 64 insert-and-copy length
/// codes, RFC 7932 section 5.
const brotliCellCopy = <int>[0, 8, 0, 8, 0, 8, 16, 0, 16, 8, 16];

/// The bits of the index of a dictionary word of each length, RFC 7932
/// section 8.
const brotliDictionaryIndexBits = <int>[
  0,
  0,
  0,
  0,
  10,
  10,
  11,
  11,
  10,
  10,
  10,
  10,
  10,
  9,
  9,
  8,
  7,
  7,
  8,
  7,
  7,
  6,
  6,
  5,
  5,
];

/// Where the dictionary words of each length start, RFC 7932 section 8.
const brotliDictionaryOffset = <int>[
  0,
  0,
  0,
  0,
  0,
  4096,
  9216,
  21504,
  35840,
  44032,
  53248,
  63488,
  74752,
  87040,
  93696,
  100864,
  104704,
  106752,
  108928,
  113536,
  115968,
  118528,
  119872,
  121280,
  122016,
];

/// The first table of the context of a literal, RFC 7932 section 7.1.
final Uint8List brotliLut0 = _bytesOfHex(
  '0000000000000000000404000004000000000000000000000000000000000000'
  '080c100c0c140c10181c0c0c200c240c2c2c2c2c2c2c2c2c2c2c202018281c0c'
  '0c3034343430343434303434343434303434343434303434343434180c1c0c0c'
  '0c383c3c3c383c3c3c383c3c3c3c3c383c3c3c3c3c383c3c3c3c3c180c1c0c00'
  '0001000100010001000100010001000100010001000100010001000100010001'
  '0001000100010001000100010001000100010001000100010001000100010001'
  '0203020302030203020302030203020302030203020302030203020302030203'
  '0203020302030203020302030203020302030203020302030203020302030203',
);

/// The second table of the context of a literal, RFC 7932 section 7.1.
final Uint8List brotliLut1 = _bytesOfHex(
  '0000000000000000000000000000000000000000000000000000000000000000'
  '0001010101010101010101010101010102020202020202020202010101010101'
  '0102020202020202020202020202020202020202020202020202020101010101'
  '0103030303030303030303030303030303030303030303030303030101010100'
  '0000000000000000000000000000000000000000000000000000000000000000'
  '0000000000000000000000000000000000000000000000000000000000000000'
  '0000000000000000000000000000000000000000000000000000000000000000'
  '0202020202020202020202020202020202020202020202020202020202020202',
);

/// The third table of the context of a literal, RFC 7932 section 7.1.
final Uint8List brotliLut2 = _bytesOfHex(
  '0001010101010101010101010101010102020202020202020202020202020202'
  '0202020202020202020202020202020202020202020202020202020202020202'
  '0303030303030303030303030303030303030303030303030303030303030303'
  '0303030303030303030303030303030303030303030303030303030303030303'
  '0404040404040404040404040404040404040404040404040404040404040404'
  '0404040404040404040404040404040404040404040404040404040404040404'
  '0505050505050505050505050505050505050505050505050505050505050505'
  '0505050505050505050505050505050506060606060606060606060606060607',
);

/// The bytes [hex] spells, two lower case hexadecimal digits each.
///
/// Returns them.
Uint8List _bytesOfHex(String hex) => Uint8List.fromList(<int>[
  for (var index = 0; index < hex.length; index += 2)
    int.parse(hex.substring(index, index + 2), radix: 16),
]);
