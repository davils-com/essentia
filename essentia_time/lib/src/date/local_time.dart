/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_time/src/date/local_date.dart';
import 'package:essentia_time/src/date/local_date_time.dart';
import 'package:essentia_time/src/internal/iso_text.dart';
import 'package:essentia_time/src/internal/time_math.dart';
import 'package:meta/meta.dart';

/// A time of day without a date and without a time zone: what a wall
/// clock shows.
///
/// It runs from [midnight] to [max], one nanosecond before the next
/// midnight, and never knows of a shift of daylight saving time.
@immutable
final class LocalTime implements Comparable<LocalTime> {
  /// The time [hour]:[minute]:[second] and [nanosecond] nanoseconds.
  ///
  /// Throws an [ArgumentError] for an hour outside 0 to 23, a minute or a
  /// second outside 0 to 59, or a nanosecond outside 0 to 999999999.
  factory LocalTime(
    int hour,
    int minute, [
    int second = 0,
    int nanosecond = 0,
  ]) {
    _check(hour, 23, 'hour');
    _check(minute, 59, 'minute');
    _check(second, 59, 'second');
    _check(nanosecond, nanosPerSecond - 1, 'nanosecond');
    return LocalTime._(hour, minute, second, nanosecond);
  }

  /// The time [seconds] seconds after midnight.
  ///
  /// Throws an [ArgumentError] outside 0 to 86399.
  factory LocalTime.fromSecondOfDay(int seconds) {
    _check(seconds, secondsPerDay - 1, 'seconds');
    return LocalTime._(seconds ~/ 3600, seconds ~/ 60 % 60, seconds % 60, 0);
  }

  /// The time [milliseconds] milliseconds after midnight.
  ///
  /// Throws an [ArgumentError] outside one day.
  factory LocalTime.fromMillisecondOfDay(int milliseconds) {
    _check(milliseconds, secondsPerDay * 1000 - 1, 'milliseconds');
    return LocalTime.fromNanosecondOfDay(milliseconds * 1000000);
  }

  /// The time [nanoseconds] nanoseconds after midnight.
  ///
  /// Throws an [ArgumentError] outside one day.
  factory LocalTime.fromNanosecondOfDay(int nanoseconds) {
    _check(nanoseconds, nanosPerDay - 1, 'nanoseconds');
    final int seconds = nanoseconds ~/ nanosPerSecond;
    return LocalTime._(
      seconds ~/ 3600,
      seconds ~/ 60 % 60,
      seconds % 60,
      nanoseconds - seconds * nanosPerSecond,
    );
  }

  /// The time of day [dateTime] reads, in its own zone.
  factory LocalTime.fromDateTime(DateTime dateTime) => LocalTime._(
    dateTime.hour,
    dateTime.minute,
    dateTime.second,
    dateTime.millisecond * 1000000 + dateTime.microsecond * 1000,
  );

  /// Reads a time written as ISO 8601 does: `09:30`, `09:30:15` or
  /// `09:30:15.250`, with up to nine digits of fraction.
  ///
  /// Throws a [FormatException] for any other text.
  factory LocalTime.parse(String text) {
    final RegExpMatch? match = _pattern.firstMatch(text);
    if (match == null) {
      throw FormatException('Not a time', text);
    }
    final int hour = int.parse(match.group(1)!);
    final int minute = int.parse(match.group(2)!);
    final int second = int.parse(match.group(3) ?? '0');
    if (hour > 23 || minute > 59 || second > 59) {
      throw FormatException('Not a time', text);
    }
    return LocalTime._(hour, minute, second, fractionNanos(match.group(4)));
  }

  /// Creates the time of valid parts.
  const LocalTime._(this.hour, this.minute, this.second, this.nanosecond);

  /// The start of a day, 00:00.
  static const midnight = LocalTime._(0, 0, 0, 0);

  /// The middle of a day, 12:00.
  static const noon = LocalTime._(12, 0, 0, 0);

  /// The last nanosecond of a day, 23:59:59.999999999.
  static const max = LocalTime._(23, 59, 59, nanosPerSecond - 1);

  /// The text of an ISO 8601 time.
  static final _pattern = RegExp(
    r'^(\d{2}):(\d{2})(?::(\d{2})(?:[.,](\d{1,9}))?)?$',
  );

  /// Throws an [ArgumentError] unless [value] lies from 0 to [highest].
  static void _check(int value, int highest, String name) {
    if (value < 0 || value > highest) {
      throw ArgumentError.value(value, name, 'Must be from 0 to $highest');
    }
  }

  /// The hour, from 0 to 23.
  final int hour;

  /// The minute of the hour, from 0 to 59.
  final int minute;

  /// The second of the minute, from 0 to 59.
  final int second;

  /// The nanosecond of the second, from 0 to 999999999.
  final int nanosecond;

  /// How many whole seconds passed since midnight.
  int toSecondOfDay() => hour * 3600 + minute * 60 + second;

  /// How many whole milliseconds passed since midnight.
  int toMillisecondOfDay() => toSecondOfDay() * 1000 + nanosecond ~/ 1000000;

  /// How many nanoseconds passed since midnight.
  int toNanosecondOfDay() => toSecondOfDay() * nanosPerSecond + nanosecond;

  /// This time on [date].
  LocalDateTime atDate(LocalDate date) => LocalDateTime(date, this);

  /// Whether this time comes before [other].
  bool isBefore(LocalTime other) => compareTo(other) < 0;

  /// Whether this time comes after [other].
  bool isAfter(LocalTime other) => compareTo(other) > 0;

  /// Orders times from midnight on.
  @override
  int compareTo(LocalTime other) =>
      toNanosecondOfDay().compareTo(other.toNanosecondOfDay());

  /// Whether [other] is the same time.
  @override
  bool operator ==(Object other) =>
      other is LocalTime &&
      other.hour == hour &&
      other.minute == minute &&
      other.second == second &&
      other.nanosecond == nanosecond;

  /// A hash of the time.
  @override
  int get hashCode => Object.hash(hour, minute, second, nanosecond);

  /// The time as ISO 8601 writes it: `09:30`, with the seconds and their
  /// fraction only when there are any.
  @override
  String toString() {
    final head = '${twoDigits(hour)}:${twoDigits(minute)}';
    if (second == 0 && nanosecond == 0) {
      return head;
    }
    return '$head:${twoDigits(second)}${isoFraction(nanosecond)}';
  }
}
