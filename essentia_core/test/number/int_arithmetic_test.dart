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
