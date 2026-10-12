/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/text/string_search.dart';
import 'package:test/test.dart';

/// The text the tests work on.
const _text = 'one two three two';

/// Covers `indexOfAny`, `lastIndexOfAny` and `splitWithLimit`.
void main() {
  test('finds the earliest of several candidates', () {
    final int index = _text.indexOfAny(<String>['three', 'two']);

    expect(index, 4);
  });

  test('finds the earliest candidate after a start', () {
    final int index = _text.indexOfAny(<String>['two'], 5);

    expect(index, 14);
  });

  test('reports minus one when no candidate occurs', () {
    final int index = _text.indexOfAny(<String>['four']);

    expect(index, -1);
  });

  test('finds the latest of several candidates', () {
    final int index = _text.lastIndexOfAny(<String>['one', 'three']);

    expect(index, 8);
  });

  test('finds the latest candidate before a start', () {
    final int index = _text.lastIndexOfAny(<String>['two'], 13);

    expect(index, 4);
  });

  test('splits into at most the given number of parts', () {
    const text = 'a,b,c,d';

    final List<String> parts = text.splitWithLimit(',', 2);

    expect(parts, <String>['a', 'b,c,d']);
  });

  test('splits at every delimiter without a limit', () {
    const text = 'a,b,c';

    final List<String> parts = text.splitWithLimit(',', 0);

    expect(parts, <String>['a', 'b', 'c']);
  });

  test('keeps the whole text as a single part when the limit is one', () {
    const text = 'a,b';

    final List<String> parts = text.splitWithLimit(',', 1);

    expect(parts, <String>['a,b']);
  });

  test('refuses an empty delimiter', () {
    List<String> split() => _text.splitWithLimit('', 2);

    expect(split, throwsArgumentError);
  });

  test('refuses a negative limit', () {
    List<String> split() => _text.splitWithLimit(' ', -1);

    expect(split, throwsRangeError);
  });

  test('hands out parts that cannot be modified', () {
    final List<String> parts = _text.splitWithLimit(' ', 0);

    void modify() => parts.add('x');

    expect(modify, throwsUnsupportedError);
  });
}
