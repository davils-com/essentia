/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/time/instant.dart';
import 'package:essentia/src/time/internal/iso_text.dart';
import 'package:essentia/src/time/local_date.dart';
import 'package:essentia/src/time/local_date_time.dart';
import 'package:essentia/src/time/local_time.dart';
import 'package:essentia/src/time/time_zone.dart';
import 'package:meta/meta.dart';

/// The last moment a recurrence rule may repeat at, the `UNTIL` of
/// RFC 5545: a [RecurrenceUntilDate], a [RecurrenceUntilLocal] or a
/// [RecurrenceUntilInstant]. The moment itself is included.
@immutable
sealed class RecurrenceUntil {
  /// Creates the end.
  const RecurrenceUntil();

  /// Reads an end as RFC 5545 writes it: `20261231`, `20261231T235959` or
  /// `20261231T235959Z`.
  ///
  /// Throws a [FormatException] for any other text.
  factory RecurrenceUntil.parse(String text) {
    final RegExpMatch? match = RegExp(
      r'^(\d{4})(\d{2})(\d{2})(?:T(\d{2})(\d{2})(\d{2})(Z)?)?$',
    ).firstMatch(text);
    if (match == null) {
      throw FormatException('Not a recurrence end', text);
    }
    final date = LocalDate.parse(
      '${match.group(1)}-${match.group(2)}-${match.group(3)}',
    );
    if (match.group(4) == null) {
      return RecurrenceUntilDate(date);
    }
    final local = LocalDateTime(
      date,
      LocalTime.parse('${match.group(4)}:${match.group(5)}:${match.group(6)}'),
    );
    if (match.group(7) == null) {
      return RecurrenceUntilLocal(local);
    }
    return RecurrenceUntilInstant(local.toInstantAt(TimeZone.utc.offset));
  }

  /// The last local time this end admits on the clocks of [zone], or of
  /// UTC for a moment without a zone.
  LocalDateTime lastLocalIn(TimeZone? zone);

  /// Whether a repetition at [local] on the clocks of [zone] lies at or
  /// before this end.
  bool admits(LocalDateTime local, TimeZone? zone) =>
      !local.isAfter(lastLocalIn(zone));

  /// The end as RFC 5545 writes it.
  String get text;

  /// [local] as RFC 5545 writes a date and time, without a zone mark.
  static String _basic(LocalDateTime local) =>
      '${_basicDate(local.date)}T${twoDigits(local.hour)}'
      '${twoDigits(local.minute)}${twoDigits(local.second)}';

  /// [date] as RFC 5545 writes it.
  static String _basicDate(LocalDate date) =>
      '${padDigits(date.year, 4)}${twoDigits(date.monthNumber)}'
      '${twoDigits(date.day)}';

  /// The end as RFC 5545 writes it.
  @override
  String toString() => text;
}

/// An end on a date: the rule repeats up to and including that day.
final class RecurrenceUntilDate extends RecurrenceUntil {
  /// The end on [date].
  const RecurrenceUntilDate(this.date);

  /// The last day.
  final LocalDate date;

  /// The last moment of [date].
  @override
  LocalDateTime lastLocalIn(TimeZone? zone) =>
      LocalDateTime(date, LocalTime.max);

  /// The date as RFC 5545 writes it.
  @override
  String get text => RecurrenceUntil._basicDate(date);

  /// Whether [other] ends on the same date.
  @override
  bool operator ==(Object other) =>
      other is RecurrenceUntilDate && other.date == date;

  /// A hash of the date.
  @override
  int get hashCode => date.hashCode;
}

/// An end at a local date and time without a zone, for a rule that
/// floats with the clocks wherever it is read.
final class RecurrenceUntilLocal extends RecurrenceUntil {
  /// The end at [local].
  const RecurrenceUntilLocal(this.local);

  /// The last local time.
  final LocalDateTime local;

  /// [local], whatever the zone.
  @override
  LocalDateTime lastLocalIn(TimeZone? zone) => local;

  /// The date and time as RFC 5545 writes it.
  @override
  String get text => RecurrenceUntil._basic(local);

  /// Whether [other] ends at the same local time.
  @override
  bool operator ==(Object other) =>
      other is RecurrenceUntilLocal && other.local == local;

  /// A hash of the local time.
  @override
  int get hashCode => local.hashCode;
}

/// An end at a moment, written in UTC; the rule of a zoned start uses
/// this one.
final class RecurrenceUntilInstant extends RecurrenceUntil {
  /// The end at [instant].
  const RecurrenceUntilInstant(this.instant);

  /// The last moment.
  final Instant instant;

  /// The local time [instant] is on the clocks of [zone], or of UTC.
  @override
  LocalDateTime lastLocalIn(TimeZone? zone) =>
      (zone ?? TimeZone.utc).toLocalDateTime(instant);

  /// Whether [local] on the clocks of [zone] happens at or before
  /// [instant].
  @override
  bool admits(LocalDateTime local, TimeZone? zone) {
    if (zone == null) {
      return super.admits(local, zone);
    }
    return !zone.toInstant(local).isAfter(instant);
  }

  /// The moment as RFC 5545 writes it, in UTC.
  @override
  String get text =>
      '${RecurrenceUntil._basic(TimeZone.utc.toLocalDateTime(instant))}Z';

  /// Whether [other] ends at the same moment.
  @override
  bool operator ==(Object other) =>
      other is RecurrenceUntilInstant && other.instant == instant;

  /// A hash of the moment.
  @override
  int get hashCode => instant.hashCode;
}
