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

import 'package:essentia_core/src/collection/set_algebra.dart';
import 'package:test/test.dart';

/// The numbers from one to three.
const _numbers = <int>{1, 2, 3};

/// Covers `plusElement`, `minusElement` and `minusAll` for sets.
void main() {
  test('adds an element into a new set', () {
    final Set<int> extended = _numbers.plusElement(4);

    expect(extended, <int>{1, 2, 3, 4});
  });

  test('removes an element into a new set', () {
    final Set<int> reduced = _numbers.minusElement(2);

    expect(reduced, <int>{1, 3});
  });

  test('removes several elements into a new set', () {
    final Set<int> reduced = _numbers.minusAll(<int>[1, 3, 5]);

    expect(reduced, <int>{2});
  });

  test('hands out a set that cannot be modified', () {
    final Set<int> extended = _numbers.plusElement(4);

    void modify() => extended.add(5);

    expect(modify, throwsUnsupportedError);
  });
}
