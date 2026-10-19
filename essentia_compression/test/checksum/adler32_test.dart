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
