/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// A month of the year.
///
/// [number] counts the months from 1 for [january] to 12 for [december].
enum Month {
  /// January.
  january,

  /// February.
  february,

  /// March.
  march,

  /// April.
  april,

  /// May.
  may,

  /// June.
  june,

  /// July.
  july,

  /// August.
  august,

  /// September.
  september,

  /// October.
  october,

  /// November.
  november,

  /// December.
  december;

  /// The month of [number], from 1 for January to 12 for December.
  ///
  /// Throws an [ArgumentError] for any other number.
  static Month of(int number) {
    if (number < 1 || number > 12) {
      throw ArgumentError.value(number, 'number', 'Must be from 1 to 12');
    }
    return values[number - 1];
  }

  /// The number of the month, from 1 for January to 12 for December.
  int get number => index + 1;

  /// How many days the month has, in a leap year when [leapYear].
  int length({required bool leapYear}) => switch (this) {
    february => leapYear ? 29 : 28,
    april || june || september || november => 30,
    january || march || may || july || august || october || december => 31,
  };

  /// The month [months] months later in the year, earlier when negative.
  Month plus(int months) => values[(index + months) % 12];
}
