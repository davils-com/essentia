/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// [value] written with at least [width] digits, zeros in front.
String padDigits(int value, int width) =>
    value.abs().toString().padLeft(width, '0');

/// [value] as two digits.
String twoDigits(int value) => padDigits(value, 2);

/// A year as ISO 8601 writes it: four digits, with a sign beyond 9999 and
/// before 0.
String isoYear(int year) {
  final String digits = padDigits(year, 4);
  if (year < 0) {
    return '-$digits';
  }
  if (year > 9999) {
    return '+$digits';
  }
  return digits;
}

/// The fraction of a second of [nanosecond] as ISO 8601 writes it, in
/// groups of three digits and with its leading dot, or nothing when it is
/// zero.
String isoFraction(int nanosecond) {
  if (nanosecond == 0) {
    return '';
  }
  if (nanosecond % 1000000 == 0) {
    return '.${padDigits(nanosecond ~/ 1000000, 3)}';
  }
  if (nanosecond % 1000 == 0) {
    return '.${padDigits(nanosecond ~/ 1000, 6)}';
  }
  return '.${padDigits(nanosecond, 9)}';
}

/// The nanoseconds of the fraction digits [digits], the part after the dot,
/// or zero when there are none.
int fractionNanos(String? digits) {
  if (digits == null || digits.isEmpty) {
    return 0;
  }
  return int.parse(digits.padRight(9, '0'));
}
