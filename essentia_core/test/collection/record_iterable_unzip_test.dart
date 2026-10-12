/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/collection/record_iterable_unzip.dart';
import 'package:test/test.dart';

/// Covers Kotlin's `unzip`.
void main() {
  test('splits pairs into their first and second parts', () {
    const pairs = <(int, String)>[(1, 'a'), (2, 'b')];

    final (List<int>, List<String>) parts = pairs.unzip();

    expect(parts.toString(), '([1, 2], [a, b])');
  });

  test('hands out parts that cannot be modified', () {
    const pairs = <(int, String)>[(1, 'a')];
    final List<int> firsts = pairs.unzip().$1;

    void modify() => firsts.add(2);

    expect(modify, throwsUnsupportedError);
  });
}
