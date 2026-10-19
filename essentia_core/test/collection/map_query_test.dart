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

import 'package:essentia_core/src/collection/map_query.dart';
import 'package:test/test.dart';

/// Ports by protocol.
const _ports = <String, int>{'http': 80, 'ssh': 22};

/// Covers asking questions about the entries of a map.
void main() {
  test('finds an entry that matches', () {
    final bool found = _ports.any((key, value) => value == 22);

    expect(found, isTrue);
  });

  test('finds no entry when none matches', () {
    final bool found = _ports.any((key, value) => value == 21);

    expect(found, isFalse);
  });

  test('confirms that every entry matches', () {
    final bool all = _ports.every((key, value) => value < 100);

    expect(all, isTrue);
  });

  test('denies that every entry matches', () {
    final bool all = _ports.every((key, value) => key.length > 3);

    expect(all, isFalse);
  });

  test('confirms that no entry matches', () {
    final bool nothing = _ports.none((key, value) => value > 1000);

    expect(nothing, isTrue);
  });

  test('counts the entries that match', () {
    final int count = _ports.countWhere((key, value) => key.length > 3);

    expect(count, 1);
  });
}
