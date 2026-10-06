/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/collection/join_format.dart';
import 'package:test/test.dart';

/// Covers the limit of `JoinFormat`.
void main() {
  test('admits every element without a limit', () {
    const format = JoinFormat();

    final bool admitted = format.admits(1000);

    expect(admitted, isTrue);
  });

  test('admits the elements up to its limit', () {
    final format = JoinFormat(limit: int.parse('2'));

    final bool admitted = format.admits(2);

    expect(admitted, isTrue);
  });

  test('refuses the elements beyond its limit', () {
    const format = JoinFormat(limit: 2);

    final bool admitted = format.admits(3);

    expect(admitted, isFalse);
  });

  test('refuses a negative limit', () {
    JoinFormat build() => JoinFormat(limit: int.parse('-1'));

    expect(build, throwsA(isA<AssertionError>()));
  });
}
