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

part of 'generate_tzdata.dart';

/// A line of a `Rule` of the database: a shift of the clocks in the years
/// [from] to [to].
final class ZicRule {
  /// The shift to [save] seconds of daylight saving in [month] on the day
  /// [day], [dayOfWeek] and [onOrBefore] tell, at [at].
  const ZicRule({
    required this.from,
    required this.to,
    required this.month,
    required this.day,
    required this.dayOfWeek,
    required this.onOrBefore,
    required this.at,
    required this.save,
  });

  /// Reads the fields of a `Rule` line after its name: FROM, TO, the
  /// unused TYPE, IN, ON, AT and SAVE.
  ///
  /// Throws a [FormatException] for fields it cannot read.
  factory ZicRule.parse(List<String> fields) {
    final int from = _year(fields[0], ZicSource.firstYear);
    final int to = switch (fields[1]) {
      'only' => from,
      'max' => ZicSource.maxYear,
      final String year => _year(year, ZicSource.maxYear),
    };
    final (int day, DayOfWeek? dayOfWeek, bool onOrBefore) = parseDay(
      fields[4],
    );
    return ZicRule(
      from: from,
      to: to,
      month: parseMonth(fields[3]),
      day: day,
      dayOfWeek: dayOfWeek,
      onOrBefore: onOrBefore,
      at: ZicTime.parse(fields[5]),
      save: ZicTime.parse(fields[6]).seconds,
    );
  }

  /// The first year of the rule.
  final int from;

  /// The last year of the rule, [ZicSource.maxYear] for "max".
  final int to;

  /// The month of the shift.
  final Month month;

  /// The day of the month, from the end when negative.
  final int day;

  /// The weekday of the shift, or `null` for exactly [day].
  final DayOfWeek? dayOfWeek;

  /// Whether the weekday lies on or before [day].
  final bool onOrBefore;

  /// The time of the shift.
  final ZicTime at;

  /// The daylight saving in seconds from the shift on.
  final int save;

  /// Whether the rule never ends.
  bool get isMax => to == ZicSource.maxYear;

  /// Whether the rule shifts the clocks in [year].
  bool covers(int year) => from <= year && year <= to;

  /// The shift as a yearly rule of a zone whose standard time is
  /// [standardOffset] seconds.
  ZoneTransitionRule toTransitionRule(int standardOffset) => ZoneTransitionRule(
    month: month,
    day: day,
    dayOfWeek: dayOfWeek,
    onOrBefore: onOrBefore,
    timeOfDay: Duration(seconds: at.seconds),
    definition: at.definition,
    offsetAfter: UtcOffset.fromTotalSeconds(standardOffset + save),
  );

  /// The local seconds since the epoch of the shift in [year], read on the
  /// clock of [at].
  int localSecondsIn(int year) =>
      toTransitionRule(0).dateIn(year).epochDays * 86400 + at.seconds;

  /// Reads a year, or [fallback] for "min" and "max".
  static int _year(String text, int fallback) =>
      text == 'min' || text == 'max' ? fallback : int.parse(text);

  /// Reads a month name such as `Mar` or `March`.
  ///
  /// Throws a [FormatException] for any other text.
  static Month parseMonth(String text) {
    final String prefix = text.toLowerCase();
    for (final Month month in Month.values) {
      if (prefix.length >= 3 && month.name.startsWith(prefix)) {
        return month;
      }
    }
    throw FormatException('Not a month', text);
  }

  /// Reads a day of a rule: `14`, `lastSun`, `Sun>=8` or `Sun<=14`.
  ///
  /// Returns the day, the weekday and whether it lies on or before.
  static (int, DayOfWeek?, bool) parseDay(String text) {
    if (text.startsWith('last')) {
      return (-1, _weekday(text.substring(4), text), true);
    }
    final RegExpMatch? match = RegExp(r'^([A-Za-z]+)([<>]=)(\d+)$')
        .firstMatch(text);
    if (match == null) {
      return (int.parse(text), null, false);
    }
    return (
      int.parse(match.group(3)!),
      _weekday(match.group(1)!, text),
      match.group(2) == '<=',
    );
  }

  /// Reads a weekday name such as `Sun` or `Sunday` within [text].
  static DayOfWeek _weekday(String name, String text) {
    final String prefix = name.toLowerCase();
    for (final DayOfWeek day in DayOfWeek.values) {
      if (prefix.length >= 2 && day.name.startsWith(prefix)) {
        return day;
      }
    }
    throw FormatException('Not a weekday', text);
  }
}
