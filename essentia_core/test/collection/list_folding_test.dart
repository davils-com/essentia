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

import 'package:essentia_core/src/collection/list_folding.dart';
import 'package:test/test.dart';

/// Three letters in alphabetical order.
const _letters = <String>['a', 'b', 'c'];

/// Covers `foldRight` and `reduceRight` for lists.
void main() {
  test('folds from the right', () {
    final String folded = _letters.foldRight(
      '!',
      (letter, text) => '$text$letter',
    );

    expect(folded, '!cba');
  });

  test('folds from the right with the index of every element', () {
    final String folded = _letters.foldRightIndexed(
      '',
      (index, letter, text) => '$text$index$letter',
    );

    expect(folded, '2c1b0a');
  });

  test('reduces from the right starting with the last element', () {
    final String reduced = _letters.reduceRight(
      (letter, text) => '$text$letter',
    );

    expect(reduced, 'cba');
  });

  test('refuses to reduce an empty list from the right', () {
    const empty = <String>[];

    String reduce() => empty.reduceRight((letter, text) => '$text$letter');

    expect(reduce, throwsStateError);
  });

  test('reduces an empty list from the right to nothing', () {
    const empty = <String>[];

    final String? reduced = empty.reduceRightOrNull(
      (letter, text) => '$text$letter',
    );

    expect(reduced, isNull);
  });

  test('reduces a list from the right when elements exist', () {
    final String? reduced = _letters.reduceRightOrNull(
      (letter, text) => '$text$letter',
    );

    expect(reduced, 'cba');
  });
}
