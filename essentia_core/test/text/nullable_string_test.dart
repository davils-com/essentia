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

import 'package:essentia_core/src/text/nullable_string.dart';
import 'package:test/test.dart';

/// Covers `isNullOrEmpty`, `isNullOrBlank` and `orEmpty` on absent text.
void main() {
  test('treats absent text as empty', () {
    const String? text = null;

    final bool empty = text.isNullOrEmpty;

    expect(empty, isTrue);
  });

  test('treats present text as not empty', () {
    const text = ' ';

    final bool empty = text.isNullOrEmpty;

    expect(empty, isFalse);
  });

  test('treats absent text as blank', () {
    const String? text = null;

    final bool blank = text.isNullOrBlank;

    expect(blank, isTrue);
  });

  test('treats whitespace as blank', () {
    const text = ' ';

    final bool blank = text.isNullOrBlank;

    expect(blank, isTrue);
  });

  test('treats a letter as not blank', () {
    const text = 'a';

    final bool blank = text.isNullOrBlank;

    expect(blank, isFalse);
  });

  test('replaces absent text with empty text', () {
    const String? text = null;

    final String value = text.orEmpty();

    expect(value, '');
  });

  test('keeps present text', () {
    const text = 'a';

    final String value = text.orEmpty();

    expect(value, 'a');
  });
}
