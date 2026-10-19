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

import 'package:essentia_core/src/collection/list_mutation.dart';
import 'package:test/test.dart';

/// Covers `removeFirst`, `removeFirstOrNull` and `removeLastOrNull`.
void main() {
  test('removes and returns the first element', () {
    final numbers = <int>[1, 2];

    final int removed = numbers.removeFirst();

    expect((removed, numbers.single), (1, 2));
  });

  test('refuses to remove the first element of an empty list', () {
    final numbers = <int>[];

    int remove() => numbers.removeFirst();

    expect(remove, throwsStateError);
  });

  test('removes the first element or nothing', () {
    final numbers = <int>[];

    final int? removed = numbers.removeFirstOrNull();

    expect(removed, isNull);
  });

  test('removes the first element when one exists', () {
    final numbers = <int>[1, 2];

    final int? removed = numbers.removeFirstOrNull();

    expect(removed, 1);
  });

  test('removes the last element or nothing', () {
    final numbers = <int>[];

    final int? removed = numbers.removeLastOrNull();

    expect(removed, isNull);
  });

  test('removes the last element when one exists', () {
    final numbers = <int>[1, 2];

    final int? removed = numbers.removeLastOrNull();

    expect(removed, 2);
  });
}
