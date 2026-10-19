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

import 'dart:io';
import 'dart:typed_data';

import 'package:essentia_compression/essentia_compression.dart';
import 'package:test/test.dart';

/// Covers deflate against the zlib of `dart:io`.
void main() {
  final data = Uint8List.fromList(<int>[
    for (var index = 0; index < 4000; index++) (index * 7) % 251,
  ]);

  test('writes what the zlib codec of dart:io reads', () async {
    expect(ZLibDecoder().convert(await deflate(data)), data);
    expect(
      ZLibDecoder(raw: true).convert(await deflate(data, raw: true)),
      data,
    );
  });

  test('reads what the zlib codec of dart:io writes', () async {
    expect(await inflate(ZLibEncoder(level: 9).convert(data)), data);
    expect(
      await inflate(ZLibEncoder(raw: true).convert(data), raw: true),
      data,
    );
  });

  test('hands on what deflate data alone held when it is cut short', () async {
    final Uint8List raw = await deflate(data, raw: true);

    final Uint8List partial = await inflate(
      raw.sublist(0, raw.length ~/ 2),
      raw: true,
    );

    expect(partial.length, lessThan(data.length));
    expect(partial, data.sublist(0, partial.length));
  });
}
