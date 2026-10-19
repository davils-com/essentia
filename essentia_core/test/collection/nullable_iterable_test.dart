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

import 'package:essentia_core/src/collection/nullable_iterable.dart';
import 'package:test/test.dart';

/// Covers `isNullOrEmpty` and `orEmpty` for an absent iterable.
void main() {
  test('treats an absent iterable as empty', () {
    const Iterable<int>? absent = null;

    final bool empty = absent.isNullOrEmpty;

    expect(empty, isTrue);
  });

  test('treats an empty iterable as empty', () {
    const Iterable<int> none = <int>[];

    final bool empty = none.isNullOrEmpty;

    expect(empty, isTrue);
  });

  test('treats an iterable with elements as not empty', () {
    const Iterable<int> some = <int>[1];

    final bool empty = some.isNullOrEmpty;

    expect(empty, isFalse);
  });

  test('replaces an absent iterable with an empty one', () {
    const Iterable<int>? absent = null;

    final Iterable<int> elements = absent.orEmpty();

    expect(elements, isEmpty);
  });

  test('keeps an iterable that is present', () {
    const Iterable<int> some = <int>[1];

    final Iterable<int> elements = some.orEmpty();

    expect(elements, <int>[1]);
  });
}
