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

import 'package:essentia_time/src/internal/iso_text.dart';
import 'package:essentia_time/src/internal/time_math.dart';
import 'package:meta/meta.dart';

/// An amount of calendar and clock time: "1 month, 2 days and 3 hours".
///
/// It is normalised: years and months are held as
/// [totalMonths], hours, minutes, seconds and nanoseconds as one exact time
/// whose parts share a sign, and [days] on their own, because a day can
/// last 23 or 25 hours. The three may carry different signs.
///
/// A period without time is a [DatePeriod].
@immutable
sealed class DateTimePeriod {
  /// The period of the given parts, a [DatePeriod] when the time is zero.
  factory DateTimePeriod({
    int years = 0,
    int months = 0,
    int days = 0,
    int hours = 0,
    int minutes = 0,
    int seconds = 0,
    int nanoseconds = 0,
  }) {
    int totalSeconds =
        hours * 3600 + minutes * 60 + seconds + nanoseconds ~/ nanosPerSecond;
    int nanos = nanoseconds.remainder(nanosPerSecond);
    if (totalSeconds > 0 && nanos < 0) {
      totalSeconds -= 1;
      nanos += nanosPerSecond;
    }
    if (totalSeconds < 0 && nanos > 0) {
      totalSeconds += 1;
      nanos -= nanosPerSecond;
    }
    final int totalMonths = years * 12 + months;
    if (totalSeconds == 0 && nanos == 0) {
      return DatePeriod._(totalMonths, days);
    }
    return _TimedPeriod._(totalMonths, days, totalSeconds, nanos);
  }

  /// Reads a period written as ISO 8601 does: `P1Y2M3DT4H5M6.5S`, `P2W`,
  /// `-P1D`, with signs on single parts allowed.
  ///
  /// Throws a [FormatException] for any other text.
  factory DateTimePeriod.parse(String text) {
    final RegExpMatch? match = _pattern.firstMatch(text);
    final bool hasPart =
        match != null &&
        <int>[2, 3, 4, 5, 6, 7, 8].any((group) => match.group(group) != null);
    if (match == null || !hasPart || text.endsWith('T')) {
      throw FormatException('Not a period', text);
    }
    final sign = match.group(1) == '-' ? -1 : 1;
    int part(int group) => int.parse(match.group(group) ?? '0') * sign;
    final String secondsText = match.group(8) ?? '0';
    final int secondsSign = secondsText.startsWith('-') ? -sign : sign;
    return DateTimePeriod(
      years: part(2),
      months: part(3),
      days: part(4) * 7 + part(5),
      hours: part(6),
      minutes: part(7),
      seconds: part(8),
      nanoseconds: fractionNanos(match.group(9)) * secondsSign,
    );
  }

  /// Creates the period of normalised parts.
  const DateTimePeriod._(
    this.totalMonths,
    this.days,
    this.secondsOfTime,
    this.nanosecondsOfTime,
  );

  /// The text of an ISO 8601 period.
  static final _pattern = RegExp(
    r'^([+-])?P(?:([+-]?\d+)Y)?(?:([+-]?\d+)M)?(?:([+-]?\d+)W)?'
    r'(?:([+-]?\d+)D)?(?:T(?:([+-]?\d+)H)?(?:([+-]?\d+)M)?'
    r'(?:([+-]?\d+)(?:[.,](\d{1,9}))?S)?)?$',
  );

  /// The years and months together, in months.
  final int totalMonths;

  /// The days.
  final int days;

  /// The whole seconds of the time part, with the sign of the time part.
  final int secondsOfTime;

  /// The nanoseconds of the time part beyond [secondsOfTime], with the
  /// same sign.
  final int nanosecondsOfTime;

  /// The whole years of [totalMonths].
  int get years => totalMonths ~/ 12;

  /// The months of [totalMonths] beyond the whole [years].
  int get months => totalMonths.remainder(12);

  /// The whole hours of the time part.
  int get hours => secondsOfTime ~/ 3600;

  /// The minutes of the time part beyond the whole [hours].
  int get minutes => (secondsOfTime ~/ 60).remainder(60);

  /// The seconds of the time part beyond the whole [minutes].
  int get seconds => secondsOfTime.remainder(60);

  /// The nanoseconds of the time part beyond the whole [seconds].
  int get nanoseconds => nanosecondsOfTime;

  /// The time part as a `Duration`, to the microsecond.
  Duration get timeDuration => Duration(
    microseconds: secondsOfTime * 1000000 + nanosecondsOfTime ~/ 1000,
  );

  /// The period with every part negated.
  DateTimePeriod operator -() => DateTimePeriod(
    months: -totalMonths,
    days: -days,
    seconds: -secondsOfTime,
    nanoseconds: -nanosecondsOfTime,
  );

  /// The sum of this period and [other], part by part.
  DateTimePeriod operator +(DateTimePeriod other) => DateTimePeriod(
    months: totalMonths + other.totalMonths,
    days: days + other.days,
    seconds: secondsOfTime + other.secondsOfTime,
    nanoseconds: nanosecondsOfTime + other.nanosecondsOfTime,
  );

  /// Whether no part is positive and some part is negative.
  bool get _allNonPositive =>
      totalMonths <= 0 &&
      days <= 0 &&
      secondsOfTime <= 0 &&
      nanosecondsOfTime <= 0 &&
      (totalMonths != 0 ||
          days != 0 ||
          secondsOfTime != 0 ||
          nanosecondsOfTime != 0);

  /// Whether [other] is a period of the same normalised parts.
  @override
  bool operator ==(Object other) =>
      other is DateTimePeriod &&
      other.totalMonths == totalMonths &&
      other.days == days &&
      other.secondsOfTime == secondsOfTime &&
      other.nanosecondsOfTime == nanosecondsOfTime;

  /// A hash of the period.
  @override
  int get hashCode =>
      Object.hash(totalMonths, days, secondsOfTime, nanosecondsOfTime);

  /// The period as ISO 8601 writes it: `P1Y2M3DT4H`,
  /// `-P1D` when no part is positive, and `P0D` when it is empty.
  @override
  String toString() {
    final sign = _allNonPositive ? -1 : 1;
    final buffer = StringBuffer(sign < 0 ? '-P' : 'P');
    void write(int value, String designator) {
      if (value != 0) {
        buffer.write('${value * sign}$designator');
      }
    }

    write(years, 'Y');
    write(months, 'M');
    write(days, 'D');
    final bool hasSeconds = seconds != 0 || nanoseconds != 0;
    if (hours != 0 || minutes != 0 || hasSeconds) {
      buffer.write('T');
    }
    write(hours, 'H');
    write(minutes, 'M');
    if (hasSeconds) {
      final whole = seconds != 0
          ? '${seconds * sign}'
          : (nanoseconds * sign < 0 ? '-0' : '0');
      final fraction = nanoseconds == 0 ? '' : '.${padDigits(nanoseconds, 9)}';
      buffer.write('$whole${fraction}S');
    }
    final text = buffer.toString();
    return text.endsWith('P') ? '${text}0D' : text;
  }
}

/// A period of years, months and days without time; what moves a
/// `LocalDate`.
final class DatePeriod extends DateTimePeriod {
  /// The period of [years], [months] and [days].
  factory DatePeriod({int years = 0, int months = 0, int days = 0}) =>
      DatePeriod._(years * 12 + months, days);

  /// Reads a period written as ISO 8601 does, without a time part:
  /// `P1Y2M3D`, `P2W`.
  ///
  /// Throws a [FormatException] for any other text, a time part included.
  factory DatePeriod.parse(String text) {
    final period = DateTimePeriod.parse(text);
    return switch (period) {
      DatePeriod() => period,
      _TimedPeriod() => throw FormatException('Not a date period', text),
    };
  }

  /// Creates the period of [totalMonths] and [days].
  const DatePeriod._(int totalMonths, int days)
    : super._(totalMonths, days, 0, 0);

  /// The period with every part negated.
  @override
  DatePeriod operator -() => DatePeriod._(-totalMonths, -days);
}

/// A period with a time part.
final class _TimedPeriod extends DateTimePeriod {
  /// Creates the period of normalised parts.
  const _TimedPeriod._(
    super.totalMonths,
    super.days,
    super.secondsOfTime,
    super.nanosecondsOfTime,
  ) : super._();
}
