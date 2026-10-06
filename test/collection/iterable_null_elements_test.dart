/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/collection/iterable_null_elements.dart';
import 'package:test/test.dart';

/// Covers Kotlin's `requireNoNulls`.
void main() {
  test('passes on elements that are all present', () {
    const numbers = <int?>[1, 2];

    final List<int> present = numbers.requireNoNulls().toList();

    expect(present, <int>[1, 2]);
  });

  test('refuses an absent element when it is reached', () {
    const numbers = <int?>[1, null];

    List<int> read() => numbers.requireNoNulls().toList();

    expect(read, throwsArgumentError);
  });
}
