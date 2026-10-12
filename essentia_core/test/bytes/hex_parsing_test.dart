/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:typed_data';

import 'package:essentia_core/src/bytes/byte_list_hex.dart';
import 'package:essentia_core/src/bytes/hex_format.dart';
import 'package:essentia_core/src/bytes/hex_format_dsl.dart';
import 'package:essentia_core/src/bytes/hex_parsing.dart';
import 'package:test/test.dart';

/// Covers writing bytes as hexadecimal digits and reading them back.
void main() {
  group('toHexString', () {
    test('writes lowercase digits by default', () {
      expect(<int>[0x00, 0x7f, 0xde, 0xad].toHexString(), '007fdead');
    });

    test('writes nothing for no bytes', () {
      expect(<int>[].toHexString(), '');
    });

    test('reads only the low eight bits of an element', () {
      expect(<int>[0x1ff, -1].toHexString(), 'ffff');
    });

    test('writes uppercase digits, separators and affixes', () {
      final HexFormat format = hexFormat((it) {
        it
          ..upperCase = true
          ..byteSeparator = ', '
          ..bytePrefix = '0x';
      });

      expect(<int>[0xab, 0x01].toHexString(format), '0xAB, 0x01');
    });

    test('writes a suffix after every byte', () {
      const format = HexFormat(byteSuffix: 'h', byteSeparator: ' ');

      expect(<int>[0x0a, 0x0b].toHexString(format), '0ah 0bh');
    });
  });

  group('hexToByteArray', () {
    test('reads digits in either case', () {
      expect('00FfAb'.hexToByteArray(), Uint8List.fromList(<int>[0, 255, 171]));
    });

    test('reads empty text as no bytes', () {
      expect(''.hexToByteArray(), isEmpty);
    });

    test('reads what a format wrote', () {
      const format = HexFormat(
        byteSeparator: ':',
        bytePrefix: '<',
        byteSuffix: '>',
      );
      final bytes = <int>[1, 2, 254];

      expect(bytes.toHexString(format).hexToByteArray(format), bytes);
    });

    test('refuses an odd number of digits', () {
      expect(
        () => 'abc'.hexToByteArray(),
        throwsA(
          isA<FormatException>()
              .having((error) => error.offset, 'offset', 3)
              .having(
                (error) => error.message,
                'message',
                'Hexadecimal text ends inside a byte',
              ),
        ),
      );
    });

    test('refuses a character that is not a digit', () {
      expect(
        () => 'zz'.hexToByteArray(),
        throwsA(
          isA<FormatException>()
              .having((error) => error.offset, 'offset', 0)
              .having((error) => error.source, 'source', isNull),
        ),
      );
    });

    test('refuses a missing separator', () {
      expect(
        () => '0102'.hexToByteArray(const HexFormat(byteSeparator: ':')),
        throwsA(
          isA<FormatException>().having((error) => error.offset, 'offset', 2),
        ),
      );
    });

    test('refuses a trailing separator', () {
      expect(
        () => '01:'.hexToByteArray(const HexFormat(byteSeparator: ':')),
        throwsFormatException,
      );
    });

    test('refuses a missing prefix', () {
      expect(
        () => '01'.hexToByteArray(const HexFormat(bytePrefix: '0x')),
        throwsFormatException,
      );
    });
  });
}
