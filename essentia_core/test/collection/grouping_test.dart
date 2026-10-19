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

import 'package:essentia_core/src/collection/grouping.dart';
import 'package:test/test.dart';

/// Three words grouped by their initial.
final _grouping = Grouping<String, String>(const <String>[
  'apple',
  'avocado',
  'banana',
], (word) => word[0]);

/// Covers the operations of a `Grouping`.
void main() {
  test('counts the elements of every group', () {
    final Map<String, int> counts = _grouping.eachCount();

    expect(counts, <String, int>{'a': 2, 'b': 1});
  });

  test('folds every group from the initial value', () {
    final Map<String, int> lengths = _grouping.fold(
      0,
      (sum, word) => sum + word.length,
    );

    expect(lengths, <String, int>{'a': 12, 'b': 6});
  });

  test('folds into absent values', () {
    final Map<String, String?> lasts = _grouping.fold<String?>(
      null,
      (_, word) => word.length > 5 ? null : word,
    );

    expect(lasts, <String, String?>{'a': null, 'b': null});
  });

  test('reduces every group starting with its first element', () {
    final Map<String, String> joined = _grouping.reduce(
      (key, text, word) => '$text+$word',
    );

    expect(joined, <String, String>{'a': 'apple+avocado', 'b': 'banana'});
  });

  test('aggregates every group with its key', () {
    final Map<String, String> aggregated = _grouping.aggregate<String>(
      (key, text, word) => '${text ?? key}:$word',
    );

    expect(aggregated, <String, String>{
      'a': 'a:apple:avocado',
      'b': 'b:banana',
    });
  });

  test('hands out groups that cannot be modified', () {
    final Map<String, int> counts = _grouping.eachCount();

    void modify() => counts['c'] = 1;

    expect(modify, throwsUnsupportedError);
  });
}
