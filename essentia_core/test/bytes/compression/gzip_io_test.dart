/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io' show GZipCodec, ZLibCodec;
import 'dart:typed_data';

import 'package:essentia_core/essentia_core.dart';
import 'package:test/test.dart';

/// Covers gzip compression on the VM, where it runs on the zlib of
/// `dart:io`: what other gzip readers and writers make of it, and levels.
void main() {
  final List<int> text = utf8.encode('Lorem ipsum dolor sit amet. ' * 400);

  test('writes what the gzip codec of dart:io reads', () async {
    expect(GZipCodec().decode(await gzip(text)), text);
  });

  test('reads what the gzip codec of dart:io writes at every level', () async {
    for (var level = 0; level <= 9; level++) {
      expect(
        await gunzip(GZipCodec(level: level).encode(text)),
        text,
        reason: 'level $level',
      );
    }
  });

  test('writes the same bytes as zlib at the same level', () async {
    expect(await gzip(text, level: 9), GZipCodec(level: 9).encode(text));
    expect(await gzip(text), GZipCodec().encode(text));
  });

  test('stores at level 0 and compresses at the others', () async {
    final Uint8List stored = await gzip(text, level: 0);
    final Uint8List smallest = await gzip(text, level: 9);

    expect(stored.length, greaterThan(text.length));
    expect(smallest.length, lessThan(text.length ~/ 20));
  });

  test('reads a header with a file name and a comment', () async {
    final Uint8List plain = await gzip(text);
    final named = <int>[
      ...plain.sublist(0, 3),
      0x18,
      ...plain.sublist(4, 10),
      ...ascii.encode('lorem.txt'),
      0,
      ...ascii.encode('a comment'),
      0,
      ...plain.sublist(10),
    ];

    expect(await gunzip(named), text);
  });

  test('refuses a zlib stream, which the zlib of dart:io would read', () async {
    final List<int> zlib = ZLibCodec().encode(text);

    await expectLater(gunzip(zlib), throwsFormatException);
  });
}
