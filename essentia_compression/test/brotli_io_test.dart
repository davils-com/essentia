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

@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io' show Directory, File, FileSystemEntity;
import 'dart:typed_data';

import 'package:essentia_compression/essentia_compression.dart';
import 'package:test/test.dart';

/// The test vectors in `test/fixtures/brotli`.
const _fixtures = 'test/fixtures/brotli';

/// Covers the Brotli decoder with the test vectors in
/// `test/fixtures/brotli`, read from files on the VM.
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
