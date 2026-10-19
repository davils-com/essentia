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

import 'package:essentia_core/src/number/rounding_mode.dart';
import 'package:meta/meta.dart';

/// An exact decimal number: an integer of any size and how many of its
/// digits lie after the decimal point.
///
/// It is what formatters count digits of, so `1.50` keeps its two fraction
/// digits, and what money is held in, so cents never become a binary
/// fraction:
///
/// ```dart
/// final price = DecimalValue.parse('19.90');
/// print(price.scale);                                   // 2
/// print(price.setScale(1, RoundingMode.halfEven));      // 19.9
/// print(DecimalValue.of(0.1 + 0.2));                    // 0.30000000000000004
/// ```
@immutable
final class DecimalValue implements Comparable<DecimalValue> {
  /// The number [unscaled] divided by ten to the power of [scale].
  ///
  /// Throws an [ArgumentError] for a negative [scale].
  factory DecimalValue(BigInt unscaled, int scale) {
    if (scale < 0) {
      throw ArgumentError.value(scale, 'scale', 'Must not be negative');
    }
    return DecimalValue._(unscaled, scale);
  }

  /// The integer [value], with no fraction digits.
  factory DecimalValue.fromInt(int value) =>
      DecimalValue._(BigInt.from(value), 0);

  /// The integer [value], with no fraction digits.
  factory DecimalValue.fromBigInt(BigInt value) => DecimalValue._(value, 0);

  /// The shortest decimal that reads back as [value], as Dart prints it:
  /// `0.1` for `0.1`, not the binary fraction behind it.
  ///
  /// Throws an [ArgumentError] for infinity and NaN.
  factory DecimalValue.fromDouble(double value) {
    if (!value.isFinite) {
      throw ArgumentError.value(value, 'value', 'Must be finite');
    }
    return DecimalValue.parse(value.toString());
  }

  /// [value] as [DecimalValue.fromInt] or [DecimalValue.fromDouble] reads
  /// it.
  factory DecimalValue.of(num value) => value is int
      ? DecimalValue.fromInt(value)
      : DecimalValue.fromDouble(value.toDouble());

  /// Reads plain or scientific decimal text: `-12.340`, `1e5`, `2.5E-3`.
  /// Trailing zeros count as digits.
  ///
  /// Throws a [FormatException] for anything else.
  factory DecimalValue.parse(String text) {
    final RegExpMatch? match = _pattern.firstMatch(text.trim());
    if (match == null) {
      throw FormatException('Not a decimal number', text);
    }
    final String sign = match.group(1) ?? '';
    final String whole = match.group(2) ?? '';
    final String fraction = match.group(3) ?? '';
    if (whole.isEmpty && fraction.isEmpty) {
      throw FormatException('Not a decimal number', text);
    }
    final int exponent = int.parse(match.group(4) ?? '0');
    final BigInt digits = BigInt.parse(
      '$sign${whole.isEmpty ? '0' : whole}$fraction',
    );
    final int scale = fraction.length - exponent;
    if (scale >= 0) {
      return DecimalValue._(digits, scale);
    }
    return DecimalValue._(digits * BigInt.from(10).pow(-scale), 0);
  }

  /// A decimal of valid parts.
  const DecimalValue._(this.unscaled, this.scale);

  /// Zero, with no fraction digits.
  static final zero = DecimalValue._(BigInt.zero, 0);

  /// The decimal text this reads.
  static final _pattern = RegExp(
    r'^([+-])?(\d*)(?:\.(\d*))?(?:[eE]([+-]?\d+))?$',
  );

  /// The digits of the number as an integer, its sign included.
  final BigInt unscaled;

  /// How many of the digits of [unscaled] lie after the decimal point.
  final int scale;

  /// Whether the number is below zero.
  bool get isNegative => unscaled.isNegative;

  /// Whether the number is zero, whatever its scale.
  bool get isZero => unscaled == BigInt.zero;

  /// Whether the number has no fraction, or only zeros after the point.
  bool get isInteger =>
      scale == 0 || unscaled.remainder(_ten(scale)) == BigInt.zero;

  /// The absolute value.
  DecimalValue abs() => isNegative ? DecimalValue._(-unscaled, scale) : this;

  /// The number with its sign flipped.
  DecimalValue operator -() => DecimalValue._(-unscaled, scale);

  /// The sum, as many fraction digits as the longer has.
  DecimalValue operator +(DecimalValue other) {
    final int common = scale > other.scale ? scale : other.scale;
    return DecimalValue._(
      _rescaled(common).unscaled + other._rescaled(common).unscaled,
      common,
    );
  }

  /// The difference, as many fraction digits as the longer has.
  DecimalValue operator -(DecimalValue other) => this + -other;

  /// The product, the fraction digits of both added.
  DecimalValue operator *(DecimalValue other) =>
      DecimalValue._(unscaled * other.unscaled, scale + other.scale);

  /// The number times ten to the power of [exponent], digits unchanged:
  /// `1.5` moved by 2 is `150`, by -2 `0.015`.
  DecimalValue movePoint(int exponent) {
    if (exponent >= scale) {
      return DecimalValue._(unscaled * _ten(exponent - scale), 0);
    }
    return DecimalValue._(unscaled, scale - exponent);
  }

  /// The number with exactly [newScale] fraction digits, rounded by
  /// [mode] when digits are dropped.
  DecimalValue setScale(int newScale, RoundingMode mode) {
    if (newScale >= scale) {
      return _rescaled(newScale);
    }
    final BigInt divisor = _ten(scale - newScale);
    return DecimalValue._(_divide(unscaled, divisor, mode), newScale);
  }

  /// The number rounded to a multiple of [increment] by [mode], keeping
  /// the scale of [increment]: `1.27` to `0.05` is `1.25`.
  DecimalValue roundToIncrement(DecimalValue increment, RoundingMode mode) {
    if (increment.isZero) {
      return this;
    }
    final int common = scale > increment.scale ? scale : increment.scale;
    final BigInt step = increment._rescaled(common).unscaled.abs();
    final BigInt count = _divide(_rescaled(common).unscaled, step, mode);
    return DecimalValue._(
      count * step,
      common,
    ).setScale(increment.scale, RoundingMode.down);
  }

  /// How many digits the number has before the point, `0` for numbers
  /// below one.
  int get integerDigitCount {
    final String digits = integerDigits;
    return digits == '0' ? 0 : digits.length;
  }

  /// How many significant digits [unscaled] has, leading zeros aside.
  int get precision =>
      unscaled == BigInt.zero ? 1 : unscaled.abs().toString().length;

  /// The decimal exponent of the leading digit: `0` for 1 to 9, `2` for
  /// 100 to 999, `-1` for 0.1 to 0.9. Zero has exponent 0.
  int get magnitude => isZero ? 0 : precision - scale - 1;

  /// The number rounded to [digits] significant digits by [mode].
  DecimalValue roundToSignificant(int digits, RoundingMode mode) {
    if (isZero) {
      return this;
    }
    final int keep = digits - magnitude - 1;
    if (keep >= scale) {
      return this;
    }
    if (keep >= 0) {
      return setScale(keep, mode);
    }
    final BigInt divisor = _ten(scale - keep);
    final BigInt rounded = _divide(unscaled, divisor, mode) * _ten(-keep);
    return DecimalValue._(rounded, 0);
  }

  /// The number without trailing zeros after the point: `1.500` is `1.5`.
  DecimalValue stripTrailingZeros() {
    BigInt value = unscaled;
    int places = scale;
    final ten = BigInt.from(10);
    while (places > 0 && value.remainder(ten) == BigInt.zero) {
      value = value ~/ ten;
      places--;
    }
    return DecimalValue._(value, places);
  }

  /// The digits before the point, without sign: `12` for `-12.5`.
  String get integerDigits {
    final text = unscaled.abs().toString();
    if (text.length <= scale) {
      return '0';
    }
    return text.substring(0, text.length - scale);
  }

  /// The digits after the point, exactly [scale] of them: `50` for `1.50`.
  String get fractionDigits {
    if (scale == 0) {
      return '';
    }
    final String text = unscaled.abs().toString().padLeft(scale + 1, '0');
    return text.substring(text.length - scale);
  }

  /// The nearest double.
  double toDouble() => double.parse(toString());

  /// Orders numbers by value; `1.5` and `1.50` are equal in order.
  @override
  int compareTo(DecimalValue other) {
    final int common = scale > other.scale ? scale : other.scale;
    return _rescaled(common).unscaled
        .compareTo(other._rescaled(common).unscaled);
  }

  /// Whether [other] has the same digits and scale; `1.5` and `1.50` are
  /// not equal.
  @override
  bool operator ==(Object other) =>
      other is DecimalValue &&
      other.unscaled == unscaled &&
      other.scale == scale;

  /// A hash of the digits and the scale.
  @override
  int get hashCode => Object.hash(unscaled, scale);

  /// The number as plain decimal text: `-12.50`.
  @override
  String toString() {
    final sign = isNegative ? '-' : '';
    if (scale == 0) {
      return '$sign$integerDigits';
    }
    return '$sign$integerDigits.$fractionDigits';
  }

  /// The number with [newScale] fraction digits, at least [scale].
  DecimalValue _rescaled(int newScale) {
    if (newScale == scale) {
      return this;
    }
    return DecimalValue._(unscaled * _ten(newScale - scale), newScale);
  }

  /// Ten to the power of [exponent].
  static BigInt _ten(int exponent) => BigInt.from(10).pow(exponent);

  /// [value] divided by the positive [divisor], rounded by [mode].
  static BigInt _divide(BigInt value, BigInt divisor, RoundingMode mode) {
    final BigInt quotient = value ~/ divisor;
    final BigInt remainder = value.remainder(divisor);
    if (remainder == BigInt.zero) {
      return quotient;
    }
    final BigInt away = value.isNegative
        ? quotient - BigInt.one
        : quotient + BigInt.one;
    final int half = (remainder.abs() * BigInt.two).compareTo(divisor);
    switch (mode) {
      case RoundingMode.down:
        return quotient;
      case RoundingMode.up:
        return away;
      case RoundingMode.ceiling:
        return value.isNegative ? quotient : away;
      case RoundingMode.floor:
        return value.isNegative ? away : quotient;
      case RoundingMode.halfUp:
        return half >= 0 ? away : quotient;
      case RoundingMode.halfDown:
        return half > 0 ? away : quotient;
      case RoundingMode.halfEven:
        if (half != 0) {
          return half > 0 ? away : quotient;
        }
        return quotient.isEven ? quotient : away;
    }
  }
}
