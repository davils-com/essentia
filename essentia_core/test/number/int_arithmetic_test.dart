/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/number/int_arithmetic.dart';
import 'package:test/test.dart';

/// Covers the floored division `floorDiv` and its modulus `mod`.
void main() {
  test('divides positive numbers downwards', () {
    final int result = 7.floorDiv(2);

    expect(result, 3);
  });

  test('divides a negative dividend downwards', () {
    final int result = (-7).floorDiv(2);

    expect(result, -4);
  });

  test('divides by a negative divisor downwards', () {
    final int result = 7.floorDiv(-2);

    expect(result, -4);
  });

  test('divides two negative numbers downwards', () {
    final int result = (-7).floorDiv(-2);

    expect(result, 3);
  });

  test('divides an exact negative quotient without rounding', () {
    final int result = (-6).floorDiv(2);

    expect(result, -3);
  });

  test('takes the modulus of positive numbers', () {
    final int result = 7.mod(3);

    expect(result, 1);
  });

  test('takes a positive modulus of a negative dividend', () {
    final int result = (-7).mod(3);

    expect(result, 2);
  });

  test('takes a negative modulus for a negative divisor', () {
    final int result = 7.mod(-3);

    expect(result, -2);
  });

  test('takes the modulus of two negative numbers', () {
    final int result = (-7).mod(-3);

    expect(result, -1);
  });

  test('takes a zero modulus of a multiple', () {
    final int result = (-6).mod(3);

    expect(result, 0);
  });

  test('refuses a divisor of zero', () {
    int divide() => 1.floorDiv(0);

    expect(divide, throwsUnsupportedError);
  });
}
