/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/time/instant.dart';
import 'package:essentia/src/time/local_date.dart';
import 'package:essentia/src/time/local_date_time.dart';
import 'package:essentia/src/time/local_time.dart';
import 'package:essentia/src/time/time_zone.dart';
import 'package:meta/meta.dart';

/// A date or a date and time of an iCalendar file: an [IcsDate] for a
/// whole day, an [IcsUtcDateTime] for a moment in UTC, an
/// [IcsZonedDateTime] for a local time in a named zone and an
/// [IcsFloatingDateTime] for a local time without one.
@immutable
sealed class IcsDateTime {
  /// Creates the value.
  const IcsDateTime();

  /// The local date and time the value reads, midnight for a day; a UTC
  /// moment reads its time in UTC.
  LocalDateTime get local;

  /// The moment of the value: a named zone found by [zoneOf], a floating
  /// time and a day read in [floatingZone].
  Instant toInstant(
    TimeZone? Function(String id) zoneOf, {
    TimeZone floatingZone = TimeZone.utc,
  });
}

/// A whole day.
final class IcsDate extends IcsDateTime {
  /// The day [date].
  const IcsDate(this.date);

  /// The day.
  final LocalDate date;

  /// Midnight of [date].
  @override
  LocalDateTime get local => LocalDateTime(date, LocalTime.midnight);

  /// The start of [date] in [floatingZone].
  @override
  Instant toInstant(
    TimeZone? Function(String id) zoneOf, {
    TimeZone floatingZone = TimeZone.utc,
  }) => floatingZone.startOfDay(date);

  /// Whether [other] is the same day.
  @override
  bool operator ==(Object other) => other is IcsDate && other.date == date;

  /// A hash of the day.
  @override
  int get hashCode => date.hashCode;

  /// Describes the day.
  @override
  String toString() => 'IcsDate($date)';
}

/// A moment, written in UTC.
final class IcsUtcDateTime extends IcsDateTime {
  /// The moment [instant].
  const IcsUtcDateTime(this.instant);

  /// The moment.
  final Instant instant;

  /// The date and time of [instant] in UTC.
  @override
  LocalDateTime get local => TimeZone.utc.toLocalDateTime(instant);

  /// [instant].
  @override
  Instant toInstant(
    TimeZone? Function(String id) zoneOf, {
    TimeZone floatingZone = TimeZone.utc,
  }) => instant;

  /// Whether [other] is the same moment.
  @override
  bool operator ==(Object other) =>
      other is IcsUtcDateTime && other.instant == instant;

  /// A hash of the moment.
  @override
  int get hashCode => instant.hashCode;

  /// Describes the moment.
  @override
  String toString() => 'IcsUtcDateTime($instant)';
}

/// A local date and time in the zone named [zoneId].
final class IcsZonedDateTime extends IcsDateTime {
  /// The local time [local] in the zone [zoneId].
  const IcsZonedDateTime(this.local, this.zoneId);

  /// The local date and time.
  @override
  final LocalDateTime local;

  /// The name of the zone, the `TZID` of the file.
  final String zoneId;

  /// The moment [local] is at in the zone [zoneOf] finds, or in
  /// [floatingZone] when it finds none.
  @override
  Instant toInstant(
    TimeZone? Function(String id) zoneOf, {
    TimeZone floatingZone = TimeZone.utc,
  }) => (zoneOf(zoneId) ?? floatingZone).toInstant(local);

  /// Whether [other] is the same local time in the same zone.
  @override
  bool operator ==(Object other) =>
      other is IcsZonedDateTime &&
      other.local == local &&
      other.zoneId == zoneId;

  /// A hash of the value.
  @override
  int get hashCode => Object.hash(local, zoneId);

  /// Describes the value.
  @override
  String toString() => 'IcsZonedDateTime($local, $zoneId)';
}

/// A local date and time that floats with the clocks.
final class IcsFloatingDateTime extends IcsDateTime {
  /// The floating time [local].
  const IcsFloatingDateTime(this.local);

  /// The local date and time.
  @override
  final LocalDateTime local;

  /// The moment [local] is at in [floatingZone].
  @override
  Instant toInstant(
    TimeZone? Function(String id) zoneOf, {
    TimeZone floatingZone = TimeZone.utc,
  }) => floatingZone.toInstant(local);

  /// Whether [other] is the same local time.
  @override
  bool operator ==(Object other) =>
      other is IcsFloatingDateTime && other.local == local;

  /// A hash of the value.
  @override
  int get hashCode => local.hashCode;

  /// Describes the value.
  @override
  String toString() => 'IcsFloatingDateTime($local)';
}
