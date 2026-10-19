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

import 'package:essentia_core/src/collection/iterable_set_algebra.dart';
import 'package:test/test.dart';

/// Numbers with a repeated element, out of order.
const _numbers = <int>[3, 1, 2, 1];

/// Covers `intersect`, `union`, `subtract` and `containsAll`.
void main() {
  test('keeps the distinct elements both sources share', () {
    final Set<int> shared = _numbers.intersect(<int>[1, 3, 5]);

    expect(shared, <int>{3, 1});
  });

  test('joins the distinct elements of both sources in order', () {
    final Set<int> joined = _numbers.union(<int>[5, 1]);

    expect(joined.toList(), <int>[3, 1, 2, 5]);
  });

  test('removes the elements of the other source', () {
    final Set<int> remaining = _numbers.subtract(<int>[1]);

    expect(remaining, <int>{3, 2});
  });

  test('hands out a set that cannot be modified', () {
    final Set<int> joined = _numbers.union(<int>[5]);

    void modify() => joined.add(7);

    expect(modify, throwsUnsupportedError);
  });

  test('contains every given element', () {
    final bool contained = _numbers.containsAll(<int>[1, 2]);

    expect(contained, isTrue);
  });

  test('misses one of the given elements', () {
    final bool contained = _numbers.containsAll(<int>[1, 4]);

    expect(contained, isFalse);
  });
}
