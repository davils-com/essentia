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

import 'package:essentia_core/src/collection/comparable_iterable_ordering.dart';
import 'package:test/test.dart';

/// Covers `sortedDescending`.
void main() {
  test('sorts comparable elements descending', () {
    const words = <String>['b', 'c', 'a'];

    final List<String> sorted = words.sortedDescending();

    expect(sorted, <String>['c', 'b', 'a']);
  });

  test('hands out a descending list that cannot be modified', () {
    const numbers = <int>[1];
    final List<int> sorted = numbers.sortedDescending();

    void modify() => sorted.add(2);

    expect(modify, throwsUnsupportedError);
  });
}
