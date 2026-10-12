/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/bytes/hex_format.dart';
import 'package:essentia_core/src/bytes/hex_format_dsl.dart';
import 'package:test/test.dart';

/// Covers the hexadecimal format and its builder.
void main() {
  test('the default format writes lowercase digits and nothing else', () {
    const HexFormat format = HexFormat.defaultFormat;

    expect(format.upperCase, isFalse);
    expect(format.isDigitsOnly, isTrue);
  });

  test('the uppercase format writes uppercase digits', () {
    expect(HexFormat.upperCaseFormat.upperCase, isTrue);
  });

  test('the builder sets every piece', () {
    final HexFormat format = hexFormat((it) {
      it
        ..upperCase = true
        ..byteSeparator = ' '
        ..bytePrefix = '0x'
        ..byteSuffix = ',';
    });

    expect(
      format,
      const HexFormat(
        upperCase: true,
        byteSeparator: ' ',
        bytePrefix: '0x',
        byteSuffix: ',',
      ),
    );
    expect(format.isDigitsOnly, isFalse);
  });

  test('equal formats share a hash code', () {
    final HexFormat colons = hexFormat((it) => it.byteSeparator = ':');

    expect(colons, const HexFormat(byteSeparator: ':'));
    expect(colons.hashCode, const HexFormat(byteSeparator: ':').hashCode);
    expect(colons, isNot(HexFormat.defaultFormat));
  });

  test('renders every piece', () {
    expect(
      const HexFormat(byteSeparator: ':').toString(),
      'HexFormat(upperCase: false, byteSeparator: ":", bytePrefix: "", '
      'byteSuffix: "")',
    );
  });
}
