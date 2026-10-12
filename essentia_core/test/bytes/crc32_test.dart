/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:convert';

import 'package:essentia_core/essentia_core.dart';
import 'package:test/test.dart';

/// Covers `Crc32`: the check values of the standard, running checks and
/// the 32 bits of the web.
void main() {
  test('is the check value of the standard for 123456789', () {
    expect(Crc32.of(ascii.encode('123456789')), 0xCBF43926);
  });

  test('matches the known checks of zlib', () {
    expect(Crc32.of(const <int>[]), 0);
    expect(Crc32.of(ascii.encode('a')), 0xE8B7BE43);
    expect(Crc32.of(const <int>[0]), 0xD202EF8D);
    expect(
      Crc32.of(ascii.encode('The quick brown fox jumps over the lazy dog')),
      0x414FA339,
    );
    expect(Crc32.of(List<int>.filled(32, 0xFF)), 0xFF6CAB0B);
  });

  test('starts at zero', () {
    expect(Crc32().value, 0);
  });

  test('runs over chunks as over the whole', () {
    final List<int> whole = utf8.encode('gzip, zip and PNG üß');
    final crc = Crc32();

    for (var start = 0; start < whole.length; start += 3) {
      crc.add(whole.sublist(start, (start + 3).clamp(0, whole.length)));
    }

    expect(crc.value, Crc32.of(whole));
    expect(crc.value, isNonNegative);
  });

  test('counts only the low eight bits of every element', () {
    expect(
      Crc32.of(const <int>[0x131, 0x132, 0x133]),
      Crc32.of(ascii.encode('123')),
    );
  });

  test('stays within 32 bits', () {
    final crc = Crc32();
    for (var round = 0; round < 1000; round++) {
      crc.add(<int>[round & 0xFF, 0xFF, 0x80]);
      expect(crc.value, inInclusiveRange(0, 0xFFFFFFFF));
    }
  });
}
