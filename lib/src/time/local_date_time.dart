/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/time/day_of_week.dart';
import 'package:essentia/src/time/instant.dart';
import 'package:essentia/src/time/internal/time_math.dart';
import 'package:essentia/src/time/local_date.dart';
import 'package:essentia/src/time/local_time.dart';
import 'package:essentia/src/time/month.dart';
import 'package:essentia/src/time/time_zone.dart';
import 'package:essentia/src/time/utc_offset.dart';
import 'package:essentia/src/time/zone_resolution.dart';
import 'package:meta/meta.dart';

/// A date and a time of day without a time zone, Kotlin's
/// `kotlinx.datetime.LocalDateTime`: what a calendar and a wall clock show
/// together.
///
/// It names no moment until a `TimeZone` or a `UtcOffset` says where the
/// clock hangs; [toInstant] and [toInstantAt] do that.
@immutable
final class LocalDateTime implements Comparable<LocalDateTime> {
  /// The [time] of day on [date].
  const LocalDateTime(this.date, this.time);

  /// The date and time of the given parts, Kotlin's seven-part constructor.
  ///
  /// Throws an [ArgumentError] for a part that does not exist.
  factory LocalDateTime.of(
    int year,
    int monthNumber,
    int day,
    int hour,
    int minute, [
    int second = 0,
    int nanosecond = 0,
  ]) => LocalDateTime(
    LocalDate(year, monthNumber, day),
    LocalTime(hour, minute, second, nanosecond),
  );

  /// The date and time [dateTime] reads, in its own zone.
  factory LocalDateTime.fromDateTime(DateTime dateTime) => LocalDateTime(
    LocalDate.fromDateTime(dateTime),
    LocalTime.fromDateTime(dateTime),
  );

  /// Reads a date and time written as ISO 8601 does:
  /// `2026-10-09T12:30`, `2026-10-09T12:30:15.5`.
  ///
  /// Throws a [FormatException] for any other text.
  factory LocalDateTime.parse(String text) {
    final int separator = text.indexOf(RegExp('[Tt]'));
    if (separator < 0) {
      throw FormatException('Not a date and time', text);
    }
    return LocalDateTime(
      LocalDate.parse(text.substring(0, separator)),
      LocalTime.parse(text.substring(separator + 1)),
    );
  }

  /// The date.
  final LocalDate date;

  /// The time of day.
  final LocalTime time;

  /// The year.
  int get year => date.year;

  /// The month.
  Month get month => date.month;

  /// The number of the month, from 1 to 12.
  int get monthNumber => date.monthNumber;

  /// The day of the month, from 1.
  int get day => date.day;

  /// The day of the week.
  DayOfWeek get dayOfWeek => date.dayOfWeek;

  /// The day of the year, from 1.
  int get dayOfYear => date.dayOfYear;

  /// The hour, from 0 to 23.
  int get hour => time.hour;

  /// The minute, from 0 to 59.
  int get minute => time.minute;

  /// The second, from 0 to 59.
  int get second => time.second;

  /// The nanosecond of the second.
  int get nanosecond => time.nanosecond;

  /// The seconds since the epoch this date and time would be at in UTC,
  /// the base of every conversion.
  int get localEpochSeconds =>
      date.epochDays * secondsPerDay + time.toSecondOfDay();

  /// The moment this date and time is at where clocks run [offset] from
  /// UTC, Kotlin's `toInstant(offset)`.
  Instant toInstantAt(UtcOffset offset) => Instant.fromEpochSeconds(
    localEpochSeconds - offset.totalSeconds,
    time.nanosecond,
  );

  /// The moment this date and time is at in [timeZone], Kotlin's
  /// `toInstant(timeZone)`.
  ///
  /// A time the clocks skip moves forward by the length of the gap; a time
  /// they pass twice takes the offset [resolution] chooses, the earlier
  /// one unless told otherwise.
  ///
  /// Throws a `DateTimeArithmeticException` for a skipped or repeated time
  /// under [ZoneResolution.strict].
  Instant toInstant(
    TimeZone timeZone, {
    ZoneResolution resolution = ZoneResolution.earlierOffset,
  }) => timeZone.toInstant(this, resolution: resolution);

  /// Whether this date and time comes before [other].
  bool isBefore(LocalDateTime other) => compareTo(other) < 0;

  /// Whether this date and time comes after [other].
  bool isAfter(LocalDateTime other) => compareTo(other) > 0;

  /// Orders dates and times by time.
  @override
  int compareTo(LocalDateTime other) {
    final int byDate = date.compareTo(other.date);
    if (byDate != 0) {
      return byDate;
    }
    return time.compareTo(other.time);
  }

  /// Whether [other] is the same date and time.
  @override
  bool operator ==(Object other) =>
      other is LocalDateTime && other.date == date && other.time == time;

  /// A hash of the date and time.
  @override
  int get hashCode => Object.hash(date, time);

  /// The date and time as ISO 8601 writes it, such as `2026-10-09T12:30`.
  @override
  String toString() => '${date}T$time';
}
