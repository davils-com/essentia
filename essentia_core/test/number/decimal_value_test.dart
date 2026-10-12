/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';
import 'package:test/test.dart';

/// Reads [text] as a decimal.
///
/// Returns the decimal.
DecimalValue _d(String text) => DecimalValue.parse(text);

/// Tests the exact decimal numbers formatters and money are built on.
void main() {
  group('creating', () {
    test('keeps the digits and the scale it is given', () {
      final value = DecimalValue(BigInt.from(1250), 2);

      expect(value.unscaled, BigInt.from(1250));
      expect(value.scale, 2);
      expect(value.toString(), '12.50');
    });

    test('refuses a negative scale', () {
      expect(() => DecimalValue(BigInt.one, -1), throwsArgumentError);
    });

    test('reads integers without fraction digits', () {
      expect(DecimalValue.fromInt(-42).toString(), '-42');
      expect(DecimalValue.fromBigInt(BigInt.from(7)).scale, 0);
      expect(DecimalValue.of(3), DecimalValue.fromInt(3));
      expect(DecimalValue.zero.toString(), '0');
    });

    test('reads a double as the shortest text that reads back', () {
      expect(DecimalValue.fromDouble(0.1).toString(), '0.1');
      expect(DecimalValue.of(2.5).toString(), '2.5');
      expect(DecimalValue.of(0.1 + 0.2).toString(), '0.30000000000000004');
    });

    test('refuses infinity and NaN', () {
      expect(
        () => DecimalValue.fromDouble(double.infinity),
        throwsArgumentError,
      );
      expect(() => DecimalValue.fromDouble(double.nan), throwsArgumentError);
    });
  });

  group('parsing', () {
    test('reads plain text and keeps trailing zeros', () {
      expect(_d('-12.340').scale, 3);
      expect(_d('-12.340').toString(), '-12.340');
      expect(_d('+7').toString(), '7');
      expect(_d(' .5 ').toString(), '0.5');
      expect(_d('5.').toString(), '5');
    });

    test('reads scientific text', () {
      expect(_d('1e5').toString(), '100000');
      expect(_d('2.5E-3').toString(), '0.0025');
      expect(_d('1.25e1').toString(), '12.5');
    });

    test('refuses what is no number', () {
      for (final text in <String>['', '.', '-', 'abc', '1.2.3', 'e5']) {
        expect(
          () => DecimalValue.parse(text),
          throwsFormatException,
          reason: text,
        );
      }
    });
  });

  group('properties', () {
    test('answers sign, zero and integer', () {
      expect(_d('-0.5').isNegative, isTrue);
      expect(_d('0.000').isZero, isTrue);
      expect(_d('3.00').isInteger, isTrue);
      expect(_d('3').isInteger, isTrue);
      expect(_d('3.10').isInteger, isFalse);
    });

    test('splits the digits around the point', () {
      expect(_d('-12.5').integerDigits, '12');
      expect(_d('0.05').integerDigits, '0');
      expect(_d('1.50').fractionDigits, '50');
      expect(_d('0.005').fractionDigits, '005');
      expect(_d('12').fractionDigits, '');
    });

    test('counts digits, precision and magnitude', () {
      expect(_d('123.4').integerDigitCount, 3);
      expect(_d('0.4').integerDigitCount, 0);
      expect(_d('0.00').precision, 1);
      expect(_d('-120.50').precision, 5);
      expect(_d('123.4').magnitude, 2);
      expect(_d('0.05').magnitude, -2);
      expect(_d('0').magnitude, 0);
    });

    test('converts to the nearest double', () {
      expect(_d('1.25').toDouble(), 1.25);
    });
  });

  group('arithmetic', () {
    test('adds and subtracts with the longer scale', () {
      expect((_d('1.5') + _d('0.25')).toString(), '1.75');
      expect((_d('1.50') + _d('2')).toString(), '3.50');
      expect((_d('1') - _d('0.25')).toString(), '0.75');
    });

    test('multiplies with the scales added', () {
      expect((_d('1.5') * _d('0.20')).toString(), '0.300');
    });

    test('negates and takes the absolute value', () {
      expect((-_d('2.5')).toString(), '-2.5');
      expect(_d('-2.5').abs().toString(), '2.5');
      expect(_d('2.5').abs(), _d('2.5'));
    });

    test('moves the point without changing the digits', () {
      expect(_d('1.5').movePoint(2).toString(), '150');
      expect(_d('1.5').movePoint(-2).toString(), '0.015');
      expect(_d('1.25').movePoint(1).toString(), '12.5');
    });

    test('strips trailing zeros after the point only', () {
      expect(_d('1.500').stripTrailingZeros().toString(), '1.5');
      expect(_d('100').stripTrailingZeros().toString(), '100');
      expect(_d('2.000').stripTrailingZeros().toString(), '2');
    });
  });

  group('rounding', () {
    /// Rounds [text] to no fraction digit by [mode].
    ///
    /// Returns the rounded text.
    String whole(String text, RoundingMode mode) =>
        _d(text).setScale(0, mode).toString();

    test('rounds by every mode as Java does', () {
      const expected = <RoundingMode, List<String>>{
        RoundingMode.ceiling: <String>['2', '-1', '3', '-2', '2'],
        RoundingMode.floor: <String>['1', '-2', '2', '-3', '2'],
        RoundingMode.down: <String>['1', '-1', '2', '-2', '2'],
        RoundingMode.up: <String>['2', '-2', '3', '-3', '2'],
        RoundingMode.halfUp: <String>['1', '-2', '3', '-3', '2'],
        RoundingMode.halfDown: <String>['1', '-2', '2', '-2', '2'],
        RoundingMode.halfEven: <String>['1', '-2', '2', '-2', '2'],
      };
      for (final MapEntry<RoundingMode, List<String>> entry
          in expected.entries) {
        expect(
          <String>[
            for (final text in <String>['1.1', '-1.9', '2.5', '-2.5', '2.0'])
              whole(text, entry.key),
          ],
          entry.value,
          reason: entry.key.name,
        );
      }
    });

    test('breaks a tie to the even neighbour', () {
      expect(whole('3.5', RoundingMode.halfEven), '4');
      expect(whole('3.6', RoundingMode.halfEven), '4');
      expect(whole('3.4', RoundingMode.halfEven), '3');
    });

    test('widens the scale without rounding', () {
      expect(_d('1.5').setScale(3, RoundingMode.down).toString(), '1.500');
    });

    test('rounds to a multiple of an increment', () {
      final DecimalValue increment = _d('0.05');

      expect(
        _d('1.27').roundToIncrement(increment, RoundingMode.halfEven),
        _d('1.25'),
      );
      expect(
        _d('1.28').roundToIncrement(increment, RoundingMode.halfEven),
        _d('1.30'),
      );
      expect(
        _d('1.27').roundToIncrement(DecimalValue.zero, RoundingMode.up),
        _d('1.27'),
      );
    });

    test('rounds to significant digits', () {
      expect(
        _d('123.456').roundToSignificant(4, RoundingMode.halfEven),
        _d('123.5'),
      );
      expect(
        _d('123456').roundToSignificant(2, RoundingMode.halfEven).toString(),
        '120000',
      );
      expect(_d('1.5').roundToSignificant(5, RoundingMode.down), _d('1.5'));
      expect(_d('0').roundToSignificant(1, RoundingMode.up), _d('0'));
    });
  });

  group('comparing', () {
    test('orders by value whatever the scale', () {
      expect(_d('1.5').compareTo(_d('1.50')), 0);
      expect(_d('1.49').compareTo(_d('1.5')), lessThan(0));
      expect(_d('-1').compareTo(_d('-2')), greaterThan(0));
    });

    test('is equal only with the same digits and scale', () {
      expect(_d('1.5'), isNot(_d('1.50')));
      expect(_d('1.50'), _d('1.50'));
      expect(_d('1.50').hashCode, _d('1.50').hashCode);
    });
  });
}
