/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';
import 'package:test/test.dart';

/// Tests how a charset is found by its name.
void main() {
  test('finds a charset by its name in any case', () {
    expect(Charset.forName('UTF-8'), same(Charsets.utf8));
    expect(Charset.forName('utf-8'), same(Charsets.utf8));
    expect(Charset.forName(' Windows-1252 '), same(Charsets.windows1252));
  });

  test('finds a charset by an alias', () {
    expect(Charset.forName('utf8'), same(Charsets.utf8));
    expect(Charset.forName('latin1'), same(Charsets.iso88591));
    expect(Charset.forName('ascii'), same(Charsets.usAscii));
    expect(Charset.forName('cp1252'), same(Charsets.windows1252));
    expect(Charset.forName('unicode'), same(Charsets.utf16));
    expect(Charset.forName('UnicodeBigUnmarked'), same(Charsets.utf16be));
    expect(Charset.forName('x-utf-16le'), same(Charsets.utf16le));
  });

  test('keeps Latin-1 and ASCII apart from windows-1252', () {
    expect(Charset.forName('iso-8859-1'), isNot(same(Charsets.windows1252)));
    expect(Charset.forName('us-ascii'), isNot(same(Charsets.windows1252)));
  });

  test('refuses a name no charset has', () {
    expect(
      () => Charset.forName('koi8-r'),
      throwsA(
        isA<UnsupportedCharsetException>()
            .having((error) => error.charsetName, 'charsetName', 'koi8-r')
            .having(
              (error) => error.toString(),
              'toString',
              'UnsupportedCharsetException: the charset "koi8-r" is not '
                  'supported',
            ),
      ),
    );
    expect(Charset.tryForName('koi8-r'), isNull);
    expect(Charset.isSupported('koi8-r'), isFalse);
    expect(Charset.isSupported('UTF-16LE'), isTrue);
  });

  test('lists every charset with a distinct name', () {
    final Set<String> names = {
      for (final Charset charset in Charset.available) charset.name,
    };

    expect(names, hasLength(7));
    expect(Charsets.utf8.toString(), 'UTF-8');
  });

  test('finds every charset by every one of its names', () {
    for (final Charset charset in Charset.available) {
      for (final String name in [charset.name, ...charset.aliases]) {
        expect(Charset.forName(name), same(charset), reason: name);
      }
    }
  });
}
