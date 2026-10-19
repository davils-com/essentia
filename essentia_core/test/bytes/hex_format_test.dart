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
