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
