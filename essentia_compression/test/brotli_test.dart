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

import 'dart:convert';
import 'dart:typed_data';

import 'package:essentia_compression/essentia_compression.dart';
import 'package:essentia_compression/src/brotli/brotli_dictionary.dart';
import 'package:essentia_compression/src/brotli/brotli_input_needed.dart';
import 'package:essentia_compression/src/brotli/brotli_tables.dart';
import 'package:essentia_compression/src/brotli/brotli_transforms.dart';
import 'package:test/test.dart';

import 'support/brotli_bit_writer.dart';

/// Covers the Brotli decoder on every platform: the tables against the
/// check values of RFC 7932, small test vectors, streams
/// written by hand that reach the corners of the format, and every way a
/// stream can be damaged.
void main() {
  group('tables', () {
    test('match the check values of RFC 7932', () {
      expect(_crc(brotliLut0), 0x8e91efb7);
      expect(_crc(brotliLut1), 0xd01a32f4);
      expect(_crc(brotliLut2), 0x0dd7a0d6);
      expect(brotliDictionary, hasLength(122784));
      expect(_crc(brotliDictionary), 0x5136cb04);
      final transforms = <int>[
        for (var id = 0; id < brotliTransformCount; id += 1) ...<int>[
          ...utf8.encode(brotliTransformPrefixes[id]),
          0,
          brotliTransformTypes[id],
          ...utf8.encode(brotliTransformSuffixes[id]),
          0,
        ],
      ];
      expect(transforms, hasLength(648));
      expect(_crc(transforms), 0x3d965f81);
    });

    test('lay the dictionary words out by length', () {
      for (var length = 4; length < 24; length += 1) {
        expect(
          brotliDictionaryOffset[length + 1],
          brotliDictionaryOffset[length] +
              length * (1 << brotliDictionaryIndexBits[length]),
        );
      }
    });
  });

  group('transforms', () {
    final word = Uint8List.fromList(<int>[
      ...utf8.encode('xaé€z'),
      0xC3,
      ...utf8.encode('abcd'),
    ]);

    test('omit bytes at either end, all of a shorter word', () {
      expect(utf8.decode(brotliTransformWord(word, 9, 4, 3)), 'bcd');
      expect(utf8.decode(brotliTransformWord(word, 9, 4, 12)), 'abc');
      expect(brotliTransformWord(word, 9, 4, 54), isEmpty);
      expect(brotliTransformWord(word, 9, 4, 64), isEmpty);
      expect(
        utf8.decode(brotliTransformWord(word, 9, 4, 73)),
        ' the abcd of the ',
      );
    });

    test('ferment the first or every character', () {
      expect(utf8.decode(brotliTransformWord(word, 9, 4, 9)), 'Abcd');
      expect(brotliTransformWord(word, 1, 8, 44), <int>[
        0x41,
        0xC3,
        0x89,
        0xE2,
        0x82,
        0xA9,
        0x5A,
        0xC3,
      ]);
      expect(brotliTransformWord(word, 3, 3, 44), <int>[0xA9, 0xE2, 0x82]);
      expect(brotliTransformWord(word, 8, 1, 9), <int>[0xC3]);
    });
  });

  group('vectors', () {
    test('decode the small test vectors', () async {
      for (final (String hex, String text) in _vectors) {
        expect(utf8.decode(await unbrotli(_bytesOf(hex))), text, reason: hex);
      }
    });

    test('decode them a byte at a time', () async {
      for (final (String hex, String text) in _vectors) {
        expect(
          utf8.decode(await _decode(_bytesOf(hex), chunk: 1)),
          text,
          reason: hex,
        );
      }
    });
  });

  group('streams written by hand', () {
    test('mix compressed, uncompressed and metadata blocks', () async {
      final Uint8List stream = _stream((it) {
        it.bits(0, 1);
        _compressedHeader(
          it,
          length: 1,
          isLast: false,
          mode: 1,
          literals: (it) => _simple(it, 8, [0x41]),
          commands: (it) => _simple(it, 10, [8]),
          distances: (it) => _simple(it, 6, [0, 1, 2]),
        );
        it
          ..bits(0, 1)
          ..bits(3, 2)
          ..bits(0, 1)
          ..bits(1, 2)
          ..bits(2, 8)
          ..bytes([1, 2, 3])
          ..bits(0, 1);
        _length(it, 3);
        it
          ..bits(1, 1)
          ..bytes(utf8.encode('xyz'))
          ..bits(0, 1)
          ..bits(3, 2)
          ..bits(0, 1)
          ..bits(0, 2)
          ..align()
          ..bits(1, 1)
          ..bits(1, 1);
      });

      expect(utf8.decode(await unbrotli(stream)), 'Axyz');
      expect(utf8.decode(await _decode(stream, chunk: 1)), 'Axyz');
    });

    test('copy from a direct distance', () async {
      final Uint8List stream = _stream((it) {
        it.bits(0, 1);
        _compressedHeader(
          it,
          length: 4,
          direct: 1,
          literals: (it) => _simple(it, 8, [0x41]),
          commands: (it) => _simple(it, 10, [137]),
          distances: (it) => _simple(it, 7, [16]),
        );
      });

      expect(utf8.decode(await unbrotli(stream)), 'AAAA');
    });

    test('wrap a small window around while copying', () async {
      final Uint8List stream = _stream((it) {
        it
          ..bits(1, 1)
          ..bits(0, 3)
          ..bits(2, 3);
        _compressedHeader(
          it,
          length: 202120,
          literals: (it) => _simple(it, 8, [0x41, 0x42, 0x43]),
          commands: (it) => _simple(it, 10, [391, 415]),
          distances: (it) => _simple(it, 6, [17, 31]),
        );
        it
          ..code(1, 1)
          ..bits(197881, 24)
          ..code(0, 1)
          ..code(2, 2)
          ..code(3, 2)
          ..code(0, 1)
          ..bits(0, 1)
          ..code(0, 1)
          ..bits(0, 24)
          ..code(1, 1)
          ..bits(235, 8);
      });
      final expected = <int>[0x41, 0x42, 0x43];
      for (var index = 0; index < 199999; index += 1) {
        expected.add(expected[expected.length - 3]);
      }
      for (var index = 0; index < 2118; index += 1) {
        expected.add(expected[expected.length - 1000]);
      }

      expect(await unbrotli(stream), expected);
      expect(await _decode(stream, chunk: 3), expected);
    });
  });

  group('damaged streams', () {
    test('refuse a window size that is none', () async {
      await _expectDamaged(
        _stream(
          (it) => it
            ..bits(1, 1)
            ..bits(0, 3)
            ..bits(1, 3),
        ),
        'window size',
      );
    });

    test('refuse lengths with needless nibbles or bytes', () async {
      await _expectDamaged(
        _stream(
          (it) => it
            ..bits(0, 2)
            ..bits(1, 2)
            ..bits(0, 20),
        ),
        'needless nibble',
      );
      await _expectDamaged(
        _stream(
          (it) => it
            ..bits(0, 2)
            ..bits(3, 2)
            ..bits(0, 1)
            ..bits(2, 2)
            ..bits(5, 8)
            ..bits(0, 8),
        ),
        'needless byte',
      );
      await _expectDamaged(
        _stream(
          (it) => it
            ..bits(0, 2)
            ..bits(3, 2)
            ..bits(1, 1),
        ),
        'reserved bit',
      );
    });

    test('refuse prefix codes that are no codes', () async {
      await _expectDamaged(
        _literalCode((it) {
          it.bits(0, 2);
          for (var index = 0; index < 18; index += 1) {
            index < 2 ? it.bits(2, 2) : it.bits(0, 2);
          }
        }),
        'code length code',
      );
      await _expectDamaged(
        _literalCode((it) => _simple(it, 8, [0x41, 0x41])),
        'simple prefix code',
      );
      await _expectDamaged(
        _literalCode((it) {
          it
            ..bits(3, 2)
            ..bits(0, 6)
            ..bits(7, 4);
          for (var index = 0; index < 11; index += 1) {
            it.bits(0, 2);
          }
          it
            ..bits(7, 3)
            ..bits(7, 3)
            ..bits(7, 3);
        }),
        'overflow the alphabet',
      );
      await _expectDamaged(
        _literalCode((it) {
          it
            ..bits(0, 2)
            ..bits(7, 4)
            ..bits(0, 6)
            ..bits(7, 4)
            ..code(1, 1);
          for (var index = 1; index < 256; index += 1) {
            it.code(0, 1);
          }
        }),
        'not complete',
      );
    });

    test('refuse a context map whose zeros overflow it', () async {
      await _expectDamaged(
        _stream((it) {
          it.bits(0, 1);
          _length(it, 1, isLast: true);
          it
            ..bits(0, 3)
            ..bits(0, 6)
            ..bits(0, 2)
            ..bits(1, 1)
            ..bits(0, 3)
            ..bits(1, 1)
            ..bits(4, 4);
          _simple(it, 3, [5]);
          it
            ..bits(31, 5)
            ..bits(0, 5);
        }),
        'context map',
      );
    });

    test('refuse commands that overflow their meta-block', () async {
      await _expectDamaged(
        _command(length: 1, commands: [16], distances: [0]),
        'inserts more',
      );
      await _expectDamaged(
        _command(
          length: 4,
          commands: [145],
          distances: [16],
          data: (it) => it.bits(0, 1),
        ),
        'copy is longer',
      );
      await _expectDamaged(
        _command(
          length: 4,
          commands: [138],
          distances: [16],
          data: (it) => it.bits(1, 1),
        ),
        'word is longer',
      );
    });

    test('refuse distances and words that are none', () async {
      await _expectDamaged(
        _command(
          length: 10,
          commands: [128, 136],
          distances: [4, 16],
          data: (it) => it
            ..code(1, 1)
            ..code(1, 1)
            ..bits(0, 1)
            ..code(0, 1)
            ..code(0, 1),
        ),
        'not positive',
      );
      await _expectDamaged(
        _command(length: 3, commands: [8], distances: [0]),
        'length the dictionary lacks',
      );
      await _expectDamaged(
        _command(
          length: 10,
          commands: [138],
          distances: [46],
          data: (it) => it.bits(0, 16),
        ),
        'transformation that is none',
      );
    });

    test('refuse set padding bits and data after the end', () async {
      await _expectDamaged(<int>[0x0E], 'padding bits');
      await expectLater(
        unbrotli(<int>[0x06, 0x00]),
        throwsA(_formatException('followed by more data')),
      );
      await expectLater(
        Stream<List<int>>.fromIterable(<List<int>>[
          <int>[0x06],
          <int>[],
          <int>[0x01],
        ]).transform(brotliDecoder()).drain<void>(),
        throwsA(_formatException('followed by more data')),
      );
    });

    test('refuse a stream cut short', () async {
      await expectLater(
        unbrotli(<int>[]),
        throwsA(_formatException('cut short')),
      );
      final Uint8List quickFox = _bytesOf(_vectors.first.$1);
      await expectLater(
        _decode(quickFox.sublist(0, quickFox.length - 1), chunk: 5),
        throwsA(_formatException('cut short')),
      );
    });
  });

  test('names the signal of too few bytes', () {
    expect(brotliInputNeeded.toString(), 'BrotliInputNeeded');
  });
}

/// Small test vectors and the text each decodes to.
const _vectors = <(String, String)>[
  (
    '0b158054686520717569636b2062726f776e20666f78206a756d7073206f76657220'
        '746865206c617a7920646f6703',
    'The quick brown fox jumps over the lazy dog',
  ),
  ('1b130000a4b0b2ea8147028a', 'XXXXXXXXXXYYYYYYYYYY'),
  ('0b028058797a7a7903', 'Xyzzy'),
  ('0000105803', 'X'),
  ('2c00580000085803', 'X'),
  ('000010580d', 'X'),
  ('a1000000008115080400', 'X'),
  ('81160058', ''),
  (
    '1b3f000024b0e2998012',
    'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
  ),
  (
    '1b760000144aac9b7abde1979d7f8ec282360e9ce09003f78b9e38e6b600abc3caa0'
        'c2da6636dccd808d2e21d76ee3ea4cb8f0d2b8c7c2704d3af0697ea1b84573abc4'
        '571e',
    'ukko nooa, ukko nooa oli kunnon mies, kun han meni saunaan, pisti '
        'laukun naulaan, ukko nooa, ukko nooa oli kunnon mies.',
  ),
];

/// The CRC-32 of [bytes].
///
/// Returns it.
int _crc(List<int> bytes) => (Crc32()..add(bytes)).value;

/// The bytes [hex] spells.
///
/// Returns them.
Uint8List _bytesOf(String hex) => Uint8List.fromList(<int>[
  for (var index = 0; index < hex.length; index += 2)
    int.parse(hex.substring(index, index + 2), radix: 16),
]);

/// The stream [body] writes.
///
/// Returns it.
Uint8List _stream(void Function(BrotliBitWriter it) body) {
  final writer = BrotliBitWriter();
  body(writer);
  return writer.done();
}

/// Decodes [bytes] handed to the decoder in chunks of [chunk] bytes.
///
/// Returns the decoded bytes.
Future<Uint8List> _decode(List<int> bytes, {required int chunk}) async {
  final builder = BytesBuilder(copy: false);
  await Stream<List<int>>.fromIterable(<List<int>>[
    for (var start = 0; start < bytes.length; start += chunk)
      bytes.sublist(
        start,
        start + chunk > bytes.length ? bytes.length : start + chunk,
      ),
  ]).transform(brotliDecoder()).forEach(builder.add);
  return builder.takeBytes();
}

/// Expects decoding [bytes] whole and a byte at a time to fail as damaged
/// with a message that contains [reason].
Future<void> _expectDamaged(List<int> bytes, String reason) async {
  await expectLater(
    unbrotli(bytes),
    throwsA(_formatException('damaged: ')),
    reason: reason,
  );
  await expectLater(
    _decode(bytes, chunk: 1),
    throwsA(_formatException(reason)),
  );
}

/// A [FormatException] whose message contains [part].
///
/// Returns the matcher.
Matcher _formatException(String part) => isA<FormatException>().having(
  (it) => it.message,
  'message',
  contains(part),
);

/// Writes a simple prefix code of [symbols] of [bits] bits each, RFC 7932
/// section 3.4.
void _simple(BrotliBitWriter writer, int bits, List<int> symbols) {
  writer
    ..bits(1, 2)
    ..bits(symbols.length - 1, 2);
  for (final symbol in symbols) {
    writer.bits(symbol, bits);
  }
}

/// Writes the meta-block length [length], after ISLAST and a clear
/// ISLASTEMPTY when [isLast].
void _length(BrotliBitWriter writer, int length, {bool isLast = false}) {
  if (isLast) {
    writer
      ..bits(1, 1)
      ..bits(0, 1);
  }
  final int bitLength = (length - 1).bitLength;
  final int nibbles = bitLength <= 16 ? 4 : (bitLength + 3) ~/ 4;
  writer
    ..bits(nibbles - 4, 2)
    ..bits(length - 1, nibbles * 4);
}

/// Writes the header of a compressed meta-block of [length] bytes, one
/// block type and prefix tree of each category, the literal context mode
/// [mode], NDIRECT [direct] and the codes [literals], [commands] and
/// [distances] write.
void _compressedHeader(
  BrotliBitWriter writer, {
  required int length,
  required void Function(BrotliBitWriter it) literals,
  required void Function(BrotliBitWriter it) commands,
  required void Function(BrotliBitWriter it) distances,
  bool isLast = true,
  int mode = 0,
  int direct = 0,
}) {
  writer.bits(isLast ? 1 : 0, 1);
  if (isLast) {
    writer.bits(0, 1);
  }
  _length(writer, length);
  if (!isLast) {
    writer.bits(0, 1);
  }
  writer
    ..bits(0, 3)
    ..bits(0, 2)
    ..bits(direct, 4)
    ..bits(mode, 2)
    ..bits(0, 2);
  literals(writer);
  commands(writer);
  distances(writer);
}

/// A stream whose literal prefix code [code] writes, and nothing after.
///
/// Returns it.
Uint8List _literalCode(void Function(BrotliBitWriter it) code) => _stream((it) {
  it.bits(0, 1);
  _compressedHeader(
    it,
    length: 1,
    literals: code,
    commands: (it) => _simple(it, 10, [8]),
    distances: (it) => _simple(it, 6, [0]),
  );
});

/// A stream of a meta-block of [length] bytes that inserts `A` and runs
/// the [commands] and [distances] whose bits [data] writes.
///
/// Returns it.
Uint8List _command({
  required int length,
  required List<int> commands,
  required List<int> distances,
  void Function(BrotliBitWriter it)? data,
}) => _stream((it) {
  it.bits(0, 1);
  _compressedHeader(
    it,
    length: length,
    literals: (it) => _simple(it, 8, [0x41]),
    commands: (it) => _simple(it, 10, commands),
    distances: (it) => _simple(it, 6, distances),
  );
  data?.call(it);
});
