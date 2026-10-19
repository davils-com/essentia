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

import 'package:essentia_core/src/collection/map_composition.dart';
import 'package:test/test.dart';

/// Ports by protocol, not sorted by key.
const _ports = <String, int>{'ssh': 22, 'http': 80, 'https': 443};

/// Covers deriving new maps by removing keys, sorting and falling back.
void main() {
  test('removes a key into a new map', () {
    final Map<String, int> reduced = _ports.minusKey('http');

    expect(reduced, <String, int>{'ssh': 22, 'https': 443});
  });

  test('removes several keys into a new map', () {
    final Map<String, int> reduced = _ports.minusKeys(<String>['http', 'ftp']);

    expect(reduced.keys, <String>['ssh', 'https']);
  });

  test('sorts its entries by the natural order of the keys', () {
    final Map<String, int> sorted = _ports.toSortedMap();

    expect(sorted.keys, <String>['http', 'https', 'ssh']);
  });

  test('sorts its entries by a comparator of the keys', () {
    final Map<String, int> sorted = _ports.toSortedMap(
      (left, right) => right.compareTo(left),
    );

    expect(sorted.keys, <String>['ssh', 'https', 'http']);
  });

  test('hands out a sorted map that cannot be modified', () {
    final Map<String, int> sorted = _ports.toSortedMap();

    void modify() => sorted['ftp'] = 21;

    expect(modify, throwsUnsupportedError);
  });

  test('keeps a map that is not empty', () {
    final Map<String, int> kept = _ports.ifEmpty(() => <String, int>{});

    expect(kept, _ports);
  });

  test('falls back when the map is empty', () {
    const empty = <String, int>{};

    final Map<String, int> kept = empty.ifEmpty(() => <String, int>{'ftp': 21});

    expect(kept, <String, int>{'ftp': 21});
  });
}
