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

import 'package:essentia_core/src/collection/nullable_list.dart';
import 'package:test/test.dart';

/// Covers `orEmpty` for an absent list.
void main() {
  test('replaces an absent list with an empty one', () {
    const List<int>? absent = null;

    final List<int> numbers = absent.orEmpty();

    expect(numbers, isEmpty);
  });

  test('replaces an absent list with one that cannot grow', () {
    const List<int>? absent = null;
    final List<int> numbers = absent.orEmpty();

    void modify() => numbers.add(1);

    expect(modify, throwsUnsupportedError);
  });

  test('keeps a list that is present', () {
    const present = <int>[1];

    final List<int> numbers = present.orEmpty();

    expect(numbers, <int>[1]);
  });
}
