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

import 'package:essentia_core/essentia_core.dart';
import 'package:test/test.dart';

/// The canonical text form of a version 4 identifier.
final _textForm = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

/// Tests the random identifier.
void main() {
  test('a minted identifier has the canonical version 4 text form', () {
    expect(UuidV4.random().toString(), matches(_textForm));
  });

  test('two identifiers are never the same', () {
    final minted = List<UuidV4>.generate(1000, (_) => UuidV4.random());

    expect(minted.toSet(), hasLength(minted.length));
  });

  test('identifiers do not arrive in the order they were minted', () {
    final minted = List<UuidV4>.generate(500, (_) => UuidV4.random());
    final sorted = List<UuidV4>.of(minted)..sort();

    expect(sorted, isNot(orderedEquals(minted)));
  });

  test('an identifier reads back from its text form as itself', () {
    final minted = UuidV4.random();

    expect(UuidV4.parse(minted.toString()), minted);
    expect(UuidV4.parse(minted.toString().toUpperCase()), minted);
  });
}
