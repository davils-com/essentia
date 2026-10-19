/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:convert';

import 'package:essentia_compression/essentia_compression.dart';
import 'package:test/test.dart';

/// The Adler-32 of [bytes], summed byte by byte as RFC 1950 defines it.
///
/// Returns the check.
int _reference(List<int> bytes) {
  var low = 1;
  var high = 0;
  for (final byte in bytes) {
    low = (low + (byte & 0xFF)) % 65521;
    high = (high + low) % 65521;
  }
  return high * 0x10000 + low;
}

/// Covers `Adler32`: the known checks, running checks and long input.
void main() {
  test('matches the known checks of zlib', () {
    expect(Adler32.of(ascii.encode('Wikipedia')), 0x11E60398);
    expect(Adler32.of(const <int>[]), 1);
    expect(Adler32.of(ascii.encode('a')), 0x00620062);
    expect(Adler32.of(List<int>.filled(100000, 0xFF)), 0x149A302C);
  });

  test('starts at one', () {
    expect(Adler32().value, 1);
  });

  test('runs over chunks as over the whole', () {
    final List<int> whole = [
      for (var index = 0; index < 20000; index++) index * 31,
    ];
    final adler = Adler32();

    for (var start = 0; start < whole.length; start += 777) {
      adler.add(whole.sublist(start, (start + 777).clamp(0, whole.length)));
    }

    expect(adler.value, Adler32.of(whole));
    expect(adler.value, _reference(whole));
  });

  test('counts only the low eight bits of every element', () {
    expect(
      Adler32.of(const <int>[0x161, 0x162]),
      Adler32.of(ascii.encode('ab')),
    );
  });
}
