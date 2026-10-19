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

import 'package:essentia_core/src/collection/iterable_ordering.dart';
import 'package:test/test.dart';

/// Covers `sortedByDescending`, `toReversedList` and `toSortedSet`.
void main() {
  test('sorts by a key descending and keeps the order of equal keys', () {
    const words = <String>['bb', 'a', 'cc', 'ddd'];

    final List<String> sorted = words.sortedByDescending((word) => word.length);

    expect(sorted, <String>['ddd', 'bb', 'cc', 'a']);
  });

  test('hands out a sorted list that cannot be modified', () {
    const words = <String>['a'];
    final List<String> sorted = words.sortedByDescending((word) => word.length);

    void modify() => sorted.add('b');

    expect(modify, throwsUnsupportedError);
  });

  test('reverses the elements into a list', () {
    const numbers = <int>[1, 2, 3];

    final List<int> reversed = numbers.toReversedList();

    expect(reversed, <int>[3, 2, 1]);
  });

  test('collects the elements into a naturally sorted set', () {
    const numbers = <int>[3, 1, 3, 2];

    final Set<int> sorted = numbers.toSortedSet();

    expect(sorted.toList(), <int>[1, 2, 3]);
  });

  test('collects the elements into a set sorted by a comparator', () {
    const numbers = <int>[3, 1, 2];

    final Set<int> sorted = numbers.toSortedSet((left, right) => right - left);

    expect(sorted.toList(), <int>[3, 2, 1]);
  });

  test('hands out a sorted set that cannot be modified', () {
    const numbers = <int>[1];
    final Set<int> sorted = numbers.toSortedSet();

    void modify() => sorted.add(2);

    expect(modify, throwsUnsupportedError);
  });
}
