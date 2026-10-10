/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/time/date_time_arithmetic_exception.dart';
import 'package:essentia/src/time/date_time_period.dart';
import 'package:essentia/src/time/date_time_unit.dart';
import 'package:essentia/src/time/internal/iso_text.dart';
import 'package:essentia/src/time/internal/time_math.dart';
import 'package:essentia/src/time/local_date_time.dart';
import 'package:essentia/src/time/time_zone.dart';
import 'package:essentia/src/time/utc_offset.dart';
import 'package:meta/meta.dart';

/// A moment on the time line, Kotlin's `kotlin.time.Instant`: the same
/// everywhere on earth, whatever a clock on the wall reads.
///
/// It counts [epochSeconds] from 1970-01-01T00:00:00Z and
/// [nanosecondsOfSecond] within that second, and covers a million years
/// either way. Every count stays exact on the web, where integers are
/// doubles.
///
/// A `TimeZone` turns it into the `LocalDateTime` a clock shows there, and
/// back.
@immutable
final class Instant implements Comparable<Instant> {
  /// The moment [epochSeconds] seconds and [nanosecondAdjustment]
  /// nanoseconds after the epoch, Kotlin's `fromEpochSeconds`.
  ///
  /// A moment beyond the range is clamped to its end, as in Kotlin.
  factory Instant.fromEpochSeconds(
    int epochSeconds, [
    int nanosecondAdjustment = 0,
  ]) => Instant._clamped(
    epochSeconds + floorDiv(nanosecondAdjustment, nanosPerSecond),
    floorMod(nanosecondAdjustment, nanosPerSecond),
  );

  /// The moment [epochMilliseconds] milliseconds after the epoch,
  /// Kotlin's `fromEpochMilliseconds`.
  factory Instant.fromEpochMilliseconds(int epochMilliseconds) =>
      Instant._clamped(
        floorDiv(epochMilliseconds, 1000),
        floorMod(epochMilliseconds, 1000) * 1000000,
      );

  /// The moment [dateTime] stands for, whatever its zone.
  factory Instant.fromDateTime(DateTime dateTime) {
    final int micros = dateTime.microsecondsSinceEpoch;
    return Instant._(
      floorDiv(micros, 1000000),
      floorMod(micros, 1000000) * 1000,
    );
  }

  /// Reads a moment written as ISO 8601 does, a local date and time with
  /// its offset: `2026-10-09T12:30:00Z` or `2026-10-09T14:30+02:00`.
  ///
  /// Throws a [FormatException] for any other text.
  factory Instant.parse(String text) {
    final RegExpMatch? match = _pattern.firstMatch(text);
    if (match == null) {
      throw FormatException('Not an instant', text);
    }
    final local = LocalDateTime.parse(match.group(1)!);
    final offset = UtcOffset.parse(match.group(2)!);
    return local.toInstantAt(offset);
  }

  /// Creates the moment of a normalised second and nanosecond.
  const Instant._(this.epochSeconds, this.nanosecondsOfSecond);

  /// The moment of [seconds] and [nanos], clamped to [min] and [max].
  factory Instant._clamped(int seconds, int nanos) {
    if (seconds < _minSeconds) {
      return min;
    }
    if (seconds > _maxSeconds) {
      return max;
    }
    return Instant._(seconds, nanos);
  }

  /// The moment of [seconds] and [nanos], or a
  /// [DateTimeArithmeticException] beyond the range.
  factory Instant._checked(int seconds, int nanos) {
    if (seconds < _minSeconds || seconds > _maxSeconds) {
      throw const DateTimeArithmeticException(
        'The result lies beyond the range of an Instant',
      );
    }
    return Instant._(seconds, nanos);
  }

  /// The epoch itself, 1970-01-01T00:00:00Z.
  static const epoch = Instant._(0, 0);

  /// A moment so far in the past that it stands for "always before",
  /// -100001-12-31T23:59:59.999999999Z, Kotlin's `DISTANT_PAST`.
  static const distantPast = Instant._(-3217862419201, nanosPerSecond - 1);

  /// A moment so far in the future that it stands for "never",
  /// +100000-01-01T00:00:00Z, Kotlin's `DISTANT_FUTURE`.
  static const distantFuture = Instant._(3093527980800, 0);

  /// The first moment there is, -1000000-01-01T00:00:00Z.
  static const min = Instant._(_minSeconds, 0);

  /// The last moment there is, +1000000-12-31T23:59:59.999999999Z.
  static const max = Instant._(_maxSeconds, nanosPerSecond - 1);

  /// The epoch second of [min].
  static const _minSeconds = -31619119219200;

  /// The epoch second of [max].
  static const _maxSeconds = 31494816403199;

  /// The largest integer every platform holds exactly, 2^53 - 1.
  static const _maxSafe = 9007199254740991;

  /// The text of an ISO 8601 moment: a local date and time, then its
  /// offset.
  static final _pattern = RegExp(
    r'^([+-]?\d{4,}-\d{2}-\d{2}[Tt]\d{2}:\d{2}(?::\d{2}(?:[.,]\d{1,9})?)?)'
    r'([Zz]|[+-]\d{2}(?::?\d{2}(?::?\d{2})?)?)$',
  );

  /// The whole seconds since the epoch, negative before it.
  final int epochSeconds;

  /// The nanoseconds within the second, from 0 to 999999999.
  final int nanosecondsOfSecond;

  /// Whether this moment lies at or before [distantPast].
  bool get isDistantPast => compareTo(distantPast) <= 0;

  /// Whether this moment lies at or after [distantFuture].
  bool get isDistantFuture => compareTo(distantFuture) >= 0;

  /// The milliseconds since the epoch, rounded down and clamped to
  /// 2^53 - 1 either way, Kotlin's `toEpochMilliseconds`.
  int toEpochMilliseconds() {
    if (epochSeconds > _maxSafe ~/ 1000 - 1) {
      return _maxSafe;
    }
    if (epochSeconds < -(_maxSafe ~/ 1000) + 1) {
      return -_maxSafe;
    }
    return epochSeconds * 1000 + nanosecondsOfSecond ~/ 1000000;
  }

  /// This moment as a `DateTime` in UTC, or in the zone of this device
  /// when [local], to the microsecond.
  ///
  /// Throws an [ArgumentError] beyond the range of a `DateTime`, about
  /// 270000 years either way.
  DateTime toDateTime({bool local = false}) {
    final utc = DateTime.fromMicrosecondsSinceEpoch(
      epochSeconds * 1000000 + nanosecondsOfSecond ~/ 1000,
      isUtc: true,
    );
    return local ? utc.toLocal() : utc;
  }

  /// The moment [duration] later, earlier when negative, clamped to the
  /// range as in Kotlin.
  Instant operator +(Duration duration) {
    final int micros = duration.inMicroseconds;
    final int nanos = nanosecondsOfSecond + floorMod(micros, 1000000) * 1000;
    return Instant._clamped(
      epochSeconds + floorDiv(micros, 1000000) + nanos ~/ nanosPerSecond,
      nanos % nanosPerSecond,
    );
  }

  /// The moment [duration] earlier, later when negative, clamped to the
  /// range as in Kotlin.
  Instant operator -(Duration duration) => this + -duration;

  /// The time from [other] to this moment, negative when [other] is later,
  /// to the microsecond; Kotlin writes it `this - other`.
  Duration difference(Instant other) => Duration(
    microseconds:
        (epochSeconds - other.epochSeconds) * 1000000 +
        (nanosecondsOfSecond - other.nanosecondsOfSecond) ~/ 1000,
  );

  /// The moment [value] times [unit] later, earlier when negative,
  /// Kotlin's `plus(value, unit)`.
  ///
  /// A time based unit adds exact time. A date based unit moves the date a
  /// clock in [timeZone] shows and keeps its time of day, so a day can last
  /// 23 or 25 hours; it needs the zone.
  ///
  /// Throws an [ArgumentError] for a date based unit without a zone, and a
  /// [DateTimeArithmeticException] beyond the range.
  Instant plus(int value, DateTimeUnit unit, {TimeZone? timeZone}) {
    switch (unit) {
      case TimeBasedUnit(:final int nanoseconds):
        final int unitSeconds = nanoseconds ~/ nanosPerSecond;
        final int unitNanos = nanoseconds % nanosPerSecond;
        final int nanos = nanosecondsOfSecond + value * unitNanos;
        return Instant._checked(
          epochSeconds + value * unitSeconds + floorDiv(nanos, nanosPerSecond),
          floorMod(nanos, nanosPerSecond),
        );
      case DateBasedUnit():
        final TimeZone zone = _zoneFor(timeZone);
        final LocalDateTime local = zone.toLocalDateTime(this);
        return zone.toInstant(
          LocalDateTime(local.date.plus(value, unit), local.time),
          preferredOffset: zone.offsetAt(this),
        );
    }
  }

  /// The moment [value] times [unit] earlier, Kotlin's `minus(value, unit)`.
  ///
  /// Throws as [plus] does.
  Instant minus(int value, DateTimeUnit unit, {TimeZone? timeZone}) =>
      plus(-value, unit, timeZone: timeZone);

  /// The moment [period] later in [timeZone], Kotlin's `plus(period, zone)`:
  /// first its months and days on the dates a clock there shows, then its
  /// time as exact time.
  ///
  /// Throws a [DateTimeArithmeticException] beyond the range.
  Instant plusPeriod(DateTimePeriod period, TimeZone timeZone) {
    var moved = this;
    if (period.totalMonths != 0 || period.days != 0) {
      final LocalDateTime local = timeZone.toLocalDateTime(this);
      moved = timeZone.toInstant(
        LocalDateTime(
          local.date.plusMonths(period.totalMonths).plusDays(period.days),
          local.time,
        ),
        preferredOffset: timeZone.offsetAt(this),
      );
    }
    final int nanos = moved.nanosecondsOfSecond + period.nanosecondsOfTime;
    return Instant._checked(
      moved.epochSeconds +
          period.secondsOfTime +
          floorDiv(nanos, nanosPerSecond),
      floorMod(nanos, nanosPerSecond),
    );
  }

  /// The moment [period] earlier in [timeZone], Kotlin's
  /// `minus(period, zone)`.
  ///
  /// Throws a [DateTimeArithmeticException] beyond the range.
  Instant minusPeriod(DateTimePeriod period, TimeZone timeZone) =>
      plusPeriod(-period, timeZone);

  /// How many whole [unit]s lie from this moment to [other], negative when
  /// [other] is earlier, Kotlin's `until`.
  ///
  /// A date based unit counts on the dates a clock in [timeZone] shows and
  /// needs the zone.
  ///
  /// Throws an [ArgumentError] for a date based unit without a zone.
  int until(Instant other, DateTimeUnit unit, {TimeZone? timeZone}) {
    switch (unit) {
      case TimeBasedUnit(:final int nanoseconds):
        int seconds = other.epochSeconds - epochSeconds;
        int nanos = other.nanosecondsOfSecond - nanosecondsOfSecond;
        if (seconds > 0 && nanos < 0) {
          seconds -= 1;
          nanos += nanosPerSecond;
        }
        if (seconds < 0 && nanos > 0) {
          seconds += 1;
          nanos -= nanosPerSecond;
        }
        if (nanoseconds % nanosPerSecond == 0) {
          return seconds ~/ (nanoseconds ~/ nanosPerSecond);
        }
        return (seconds * nanosPerSecond + nanos) ~/ nanoseconds;
      case DayBasedUnit(:final int days):
        return _wholeUnitsUntil(other, DateTimeUnit.day, _zoneFor(timeZone)) ~/
            days;
      case MonthBasedUnit(:final int months):
        return _wholeUnitsUntil(
              other,
              DateTimeUnit.month,
              _zoneFor(timeZone),
            ) ~/
            months;
    }
  }

  /// How many whole days lie from this moment to [other] in [timeZone].
  int daysUntil(Instant other, TimeZone timeZone) =>
      until(other, DateTimeUnit.day, timeZone: timeZone);

  /// How many whole months lie from this moment to [other] in [timeZone].
  int monthsUntil(Instant other, TimeZone timeZone) =>
      until(other, DateTimeUnit.month, timeZone: timeZone);

  /// How many whole years lie from this moment to [other] in [timeZone].
  int yearsUntil(Instant other, TimeZone timeZone) =>
      until(other, DateTimeUnit.year, timeZone: timeZone);

  /// The period from this moment to [other] in [timeZone], Kotlin's
  /// `periodUntil`: whole months, then whole days, then the exact time
  /// that remains, all with one sign.
  DateTimePeriod periodUntil(Instant other, TimeZone timeZone) {
    final int months = _wholeUnitsUntil(other, DateTimeUnit.month, timeZone);
    final Instant afterMonths = plus(
      months,
      DateTimeUnit.month,
      timeZone: timeZone,
    );
    final int days = afterMonths._wholeUnitsUntil(
      other,
      DateTimeUnit.day,
      timeZone,
    );
    final Instant afterDays = afterMonths.plus(
      days,
      DateTimeUnit.day,
      timeZone: timeZone,
    );
    return DateTimePeriod(
      months: months,
      days: days,
      seconds: other.epochSeconds - afterDays.epochSeconds,
      nanoseconds: other.nanosecondsOfSecond - afterDays.nanosecondsOfSecond,
    );
  }

  /// The date and time a clock in [timeZone] shows at this moment,
  /// Kotlin's `toLocalDateTime`.
  LocalDateTime toLocalDateTime(TimeZone timeZone) =>
      timeZone.toLocalDateTime(this);

  /// The offset [timeZone] has from UTC at this moment, Kotlin's
  /// `offsetIn`.
  UtcOffset offsetIn(TimeZone timeZone) => timeZone.offsetAt(this);

  /// How many whole [unit]s, a day or a month, lie from this moment to
  /// [other] on the clocks of [timeZone].
  int _wholeUnitsUntil(Instant other, DateBasedUnit unit, TimeZone timeZone) {
    final LocalDateTime from = timeZone.toLocalDateTime(this);
    final LocalDateTime to = timeZone.toLocalDateTime(other);
    int count = switch (unit) {
      DayBasedUnit() => from.date.daysUntil(to.date),
      MonthBasedUnit() =>
        (to.year - from.year) * 12 + to.monthNumber - from.monthNumber,
    };
    while (count > 0 &&
        plus(count, unit, timeZone: timeZone).compareTo(other) > 0) {
      count -= 1;
    }
    while (count < 0 &&
        plus(count, unit, timeZone: timeZone).compareTo(other) < 0) {
      count += 1;
    }
    return count;
  }

  /// [timeZone], or an [ArgumentError] when a date based unit has none.
  TimeZone _zoneFor(TimeZone? timeZone) {
    if (timeZone == null) {
      throw ArgumentError.notNull('timeZone');
    }
    return timeZone;
  }

  /// Whether this moment comes before [other].
  bool isBefore(Instant other) => compareTo(other) < 0;

  /// Whether this moment comes after [other].
  bool isAfter(Instant other) => compareTo(other) > 0;

  /// Orders moments by time.
  @override
  int compareTo(Instant other) {
    final int seconds = epochSeconds.compareTo(other.epochSeconds);
    if (seconds != 0) {
      return seconds;
    }
    return nanosecondsOfSecond.compareTo(other.nanosecondsOfSecond);
  }

  /// Whether [other] is the same moment.
  @override
  bool operator ==(Object other) =>
      other is Instant &&
      other.epochSeconds == epochSeconds &&
      other.nanosecondsOfSecond == nanosecondsOfSecond;

  /// A hash of the moment.
  @override
  int get hashCode => Object.hash(epochSeconds, nanosecondsOfSecond);

  /// The moment as ISO 8601 writes it in UTC, such as
  /// `2026-10-09T12:30:00Z`, with a fraction only when there is one.
  @override
  String toString() {
    final LocalDateTime local = TimeZone.utc.toLocalDateTime(this);
    return '${local.date}T${twoDigits(local.hour)}:${twoDigits(local.minute)}'
        ':${twoDigits(local.second)}${isoFraction(local.nanosecond)}Z';
  }
}
