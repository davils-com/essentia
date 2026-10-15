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
import 'dart:io' show Directory, File, FileSystemEntity;
import 'dart:typed_data';

import 'package:essentia_core/essentia_core.dart';
import 'package:test/test.dart';

/// The test vectors of google/brotli 1.1.0 in `test/fixtures/brotli`.
const _fixtures = 'test/fixtures/brotli';

/// Covers the Brotli decoder with the test vectors of google/brotli, read
/// from files on the VM.
void main() {
  final List<File> vectors =
      Directory(_fixtures)
          .listSync()
          .whereType<File>()
          .where((it) => it.path.contains('.compressed'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  test('finds the vectors', () {
    expect(vectors.length, greaterThan(30));
  });

  for (final vector in vectors) {
    final String name = vector.uri.pathSegments.last;
    test('decodes $name', () async {
      final Uint8List compressed = vector.readAsBytesSync();
      final Uint8List expected = _original(name);

      expect(await unbrotli(compressed), expected);
    });
  }

  test('decodes as the bytes arrive one by one or in odd chunks', () async {
    for (final name in [
      'alice29.txt.compressed',
      'mapsdatazrh.compressed',
      'random_org_10k.bin.compressed',
      'ukkonooa.compressed',
      'x.compressed.03',
    ]) {
      final Uint8List compressed = File('$_fixtures/$name').readAsBytesSync();
      for (final size in [1, 7, 4093]) {
        final builder = BytesBuilder();
        await Stream<List<int>>.fromIterable([
          for (var start = 0; start < compressed.length; start += size)
            compressed.sublist(
              start,
              start + size > compressed.length
                  ? compressed.length
                  : start + size,
            ),
        ]).transform(brotliDecoder()).forEach(builder.add);

        expect(builder.takeBytes(), _original(name), reason: '$name/$size');
      }
    }
  });
}

/// The bytes the vector [name] decodes to.
///
/// Returns them.
Uint8List _original(String name) {
  final String base = name.substring(0, name.indexOf('.compressed'));
  if (base == 'zeros') {
    return Uint8List(262144);
  }
  if (base == 'quickfox_repeated') {
    return utf8.encode('The quick brown fox jumps over the lazy dog' * 4096);
  }
  final file = File('$_fixtures/$base');
  expect(FileSystemEntity.isFileSync(file.path), isTrue, reason: base);
  return file.readAsBytesSync();
}
