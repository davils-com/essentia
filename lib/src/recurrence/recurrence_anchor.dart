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

/// Where a recurrence starts, the `DTSTART` of RFC 5545: a [DateAnchor]
/// for a whole day, a [FloatingAnchor] for a local time that floats with
/// the clocks wherever it is read, or a [ZonedAnchor] for a local time in
/// a time zone.
///
/// Repetitions are computed on the local clock of the anchor, so a rule in
/// a zone keeps its time of day across shifts of daylight saving time.
@immutable
sealed class RecurrenceAnchor {
  /// Creates the anchor.
  const RecurrenceAnchor();

  /// The local date and time the recurrence starts at; midnight for a
  /// whole day.
  LocalDateTime get local;

  /// The zone the local times are read in, or `null` when they float.
  TimeZone? get zone;

  /// The anchor moved to [local], in the same zone.
  RecurrenceAnchor movedTo(LocalDateTime local);

  /// The moment [local] is at, or `null` when it floats.
  Instant? instantOf(LocalDateTime local) => zone?.toInstant(local);
}

/// A recurrence of whole days, starting on [date].
final class DateAnchor extends RecurrenceAnchor {
  /// The anchor on [date].
  const DateAnchor(this.date);

  /// The first day.
  final LocalDate date;

  /// Midnight of [date].
  @override
  LocalDateTime get local => LocalDateTime(date, LocalTime.midnight);

  /// None: days float.
  @override
  TimeZone? get zone => null;

  /// The anchor on the date of [local].
  @override
  DateAnchor movedTo(LocalDateTime local) => DateAnchor(local.date);

  /// Whether [other] starts on the same day.
  @override
  bool operator ==(Object other) => other is DateAnchor && other.date == date;

  /// A hash of the day.
  @override
  int get hashCode => date.hashCode;

  /// Describes the anchor.
  @override
  String toString() => 'DateAnchor($date)';
}

/// A recurrence of a local time without a zone.
final class FloatingAnchor extends RecurrenceAnchor {
  /// The anchor at [local].
  const FloatingAnchor(this.local);

  /// The first local date and time.
  @override
  final LocalDateTime local;

  /// None: the time floats.
  @override
  TimeZone? get zone => null;

  /// The anchor at [local].
  @override
  FloatingAnchor movedTo(LocalDateTime local) => FloatingAnchor(local);

  /// Whether [other] starts at the same local time.
  @override
  bool operator ==(Object other) =>
      other is FloatingAnchor && other.local == local;

  /// A hash of the local time.
  @override
  int get hashCode => local.hashCode;

  /// Describes the anchor.
  @override
  String toString() => 'FloatingAnchor($local)';
}

/// A recurrence of a local time in a time zone.
final class ZonedAnchor extends RecurrenceAnchor {
  /// The anchor at [local] in [zone].
  const ZonedAnchor(this.local, this.zone);

  /// The anchor at the local time [instant] is at in [zone].
  factory ZonedAnchor.at(Instant instant, TimeZone zone) =>
      ZonedAnchor(zone.toLocalDateTime(instant), zone);

  /// The first local date and time.
  @override
  final LocalDateTime local;

  /// The zone the local times are read in.
  @override
  final TimeZone zone;

  /// The anchor at [local] in [zone].
  @override
  ZonedAnchor movedTo(LocalDateTime local) => ZonedAnchor(local, zone);

  /// The moment [local] is at in [zone].
  @override
  Instant instantOf(LocalDateTime local) => zone.toInstant(local);

  /// Whether [other] starts at the same local time in the same zone.
  @override
  bool operator ==(Object other) =>
      other is ZonedAnchor && other.local == local && other.zone == zone;

  /// A hash of the local time and zone.
  @override
  int get hashCode => Object.hash(local, zone);

  /// Describes the anchor.
  @override
  String toString() => 'ZonedAnchor($local, $zone)';
}
