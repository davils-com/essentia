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

import 'package:essentia_time/essentia_time.dart';
import 'package:test/test.dart';

/// Covers the days of the week and the months.
void main() {
  test('numbers the days of the week as ISO 8601 does', () {
    expect(DayOfWeek.monday.isoDayNumber, 1);
    expect(DayOfWeek.sunday.isoDayNumber, 7);
    expect(DayOfWeek.of(4), DayOfWeek.thursday);
    expect(DayOfWeek.of(DateTime.sunday), DayOfWeek.sunday);
    expect(() => DayOfWeek.of(0), throwsArgumentError);
    expect(() => DayOfWeek.of(8), throwsArgumentError);
  });

  test('moves through the week both ways', () {
    expect(DayOfWeek.saturday.plus(2), DayOfWeek.monday);
    expect(DayOfWeek.monday.plus(-1), DayOfWeek.sunday);
    expect(DayOfWeek.monday.plus(14), DayOfWeek.monday);
    expect(DayOfWeek.friday.daysUntil(DayOfWeek.monday), 3);
    expect(DayOfWeek.monday.daysUntil(DayOfWeek.monday), 0);
  });

  test('numbers the months and knows their lengths', () {
    expect(Month.january.number, 1);
    expect(Month.of(12), Month.december);
    expect(() => Month.of(0), throwsArgumentError);
    expect(() => Month.of(13), throwsArgumentError);
    expect(Month.february.length(leapYear: false), 28);
    expect(Month.february.length(leapYear: true), 29);
    expect(Month.april.length(leapYear: false), 30);
    expect(Month.august.length(leapYear: false), 31);
    expect(Month.november.plus(3), Month.february);
    expect(Month.january.plus(-1), Month.december);
  });
}
