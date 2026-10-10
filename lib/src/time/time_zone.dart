/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/time/current_time_zone.dart';
import 'package:essentia/src/time/date_time_arithmetic_exception.dart';
import 'package:essentia/src/time/illegal_time_zone_exception.dart';
import 'package:essentia/src/time/instant.dart';
import 'package:essentia/src/time/internal/time_math.dart';
import 'package:essentia/src/time/internal/zone_database.dart';
import 'package:essentia/src/time/local_date.dart';
import 'package:essentia/src/time/local_date_time.dart';
import 'package:essentia/src/time/local_time.dart';
import 'package:essentia/src/time/utc_offset.dart';
import 'package:essentia/src/time/zone_offset_info.dart';
import 'package:essentia/src/time/zone_resolution.dart';
import 'package:essentia/src/time/zone_rules.dart';
import 'package:essentia/src/time/zone_transition.dart';
import 'package:meta/meta.dart';

/// A time zone, Kotlin's `kotlinx.datetime.TimeZone`: the rules by which
/// the clocks of a region relate to UTC, daylight saving time included.
///
/// [of] reads a zone of the IANA time zone database, such as
/// `Europe/Berlin`, or a fixed offset such as `+02:00` or `UTC+2`; the
/// whole database is built in, so it works the same on every platform.
/// [currentSystemDefault] is the zone of the system the program runs on.
///
/// A zone converts between an [Instant] and the [LocalDateTime] its
/// clocks show.
@immutable
sealed class TimeZone {
  /// Creates a zone of [id].
  const TimeZone._(this.id);

  /// The zone [zoneId] names, Kotlin's `TimeZone.of`.
  ///
  /// [zoneId] is an identifier of the time zone database such as
  /// `Europe/Berlin`, `UTC` or `Z`, an offset such as `+02:00`, or an
  /// offset after `UTC`, `GMT` or `UT` such as `UTC+02:00` or `GMT-3`.
  ///
  /// Throws an [IllegalTimeZoneException] for any other identifier.
  static TimeZone of(String zoneId) {
    if (zoneId == 'Z') {
      return FixedOffsetTimeZone(UtcOffset.zero, id: 'Z');
    }
    if (zoneId == 'UTC' || zoneId == 'GMT' || zoneId == 'UT') {
      return FixedOffsetTimeZone(UtcOffset.zero, id: zoneId);
    }
    if (zoneId.startsWith('+') || zoneId.startsWith('-')) {
      return FixedOffsetTimeZone(_offsetOf(zoneId, zoneId));
    }
    final RegExpMatch? prefixed = RegExp(r'^(UTC|GMT|UT)([+-].+)$')
        .firstMatch(zoneId);
    if (prefixed != null) {
      final UtcOffset offset = _offsetOf(prefixed.group(2)!, zoneId);
      return FixedOffsetTimeZone(
        offset,
        id: offset == UtcOffset.zero
            ? prefixed.group(1)!
            : '${prefixed.group(1)}$offset',
      );
    }
    final ZoneRules? rules = zoneRulesOf(zoneId);
    if (rules == null) {
      throw IllegalTimeZoneException('Unknown time zone: $zoneId');
    }
    return _RuleTimeZone(zoneId, rules);
  }

  /// The zone [zoneId] names, or `null` when there is none.
  static TimeZone? ofOrNull(String zoneId) {
    try {
      return of(zoneId);
    } on IllegalTimeZoneException {
      return null;
    }
  }

  /// A zone of [id] that follows [rules], such as a time zone a calendar
  /// file describes.
  static TimeZone fromRules(String id, ZoneRules rules) {
    if (rules.isFixed) {
      return FixedOffsetTimeZone(rules.initialOffset, id: id);
    }
    return _RuleTimeZone(id, rules);
  }

  /// UTC itself, Kotlin's `TimeZone.UTC`.
  static const utc = FixedOffsetTimeZone._(UtcOffset.zero, 'UTC');

  /// The zone of the system the program runs on, Kotlin's
  /// `currentSystemDefault`.
  ///
  /// Where the system does not tell its zone by name, which Android, iOS
  /// and Windows do not to a program, this is a fixed offset, the one the
  /// system has now; an application there hands its zone in instead.
  static TimeZone currentSystemDefault() {
    final String? id = systemTimeZoneId();
    if (id != null) {
      final TimeZone? zone = ofOrNull(id);
      if (zone != null) {
        return zone;
      }
    }
    return FixedOffsetTimeZone(
      UtcOffset.fromTotalSeconds(DateTime.now().timeZoneOffset.inSeconds),
    );
  }

  /// The identifiers of every zone of the built-in database, links
  /// included, Kotlin's `availableZoneIds`.
  static Set<String> get availableZoneIds => zoneIds();

  /// The version of the built-in time zone database, such as `2026a`.
  static String get databaseVersion => zoneDatabaseVersion;

  /// [text] as an offset, or an [IllegalTimeZoneException] naming
  /// [zoneId].
  static UtcOffset _offsetOf(String text, String zoneId) {
    final RegExpMatch? short = RegExp(r'^([+-])(\d{1,2})$').firstMatch(text);
    final normalised = short == null
        ? text
        : '${short.group(1)}${short.group(2)!.padLeft(2, '0')}';
    try {
      return UtcOffset.parse(normalised);
    } on FormatException {
      throw IllegalTimeZoneException('Unknown time zone: $zoneId');
    }
  }

  /// The identifier of the zone, such as `Europe/Berlin` or `+02:00`.
  final String id;

  /// The offsets of the zone over time.
  ZoneRules get rules;

  /// The offset of the zone at [instant], Kotlin's `offsetAt`.
  UtcOffset offsetAt(Instant instant) => rules.offsetAt(instant);

  /// What the zone makes of [local]: one offset, or the shift of the
  /// clocks that skips or repeats it.
  ZoneOffsetInfo offsetInfo(LocalDateTime local) => rules.infoAt(local);

  /// The date and time the clocks of the zone show at [instant], Kotlin's
  /// `Instant.toLocalDateTime(zone)`.
  LocalDateTime toLocalDateTime(Instant instant) {
    final int seconds = instant.epochSeconds + offsetAt(instant).totalSeconds;
    final int secondOfDay = floorMod(seconds, secondsPerDay);
    return LocalDateTime(
      LocalDate.fromEpochDays(floorDiv(seconds, secondsPerDay)),
      LocalTime.fromNanosecondOfDay(
        secondOfDay * nanosPerSecond + instant.nanosecondsOfSecond,
      ),
    );
  }

  /// The moment at which the clocks of the zone show [local], Kotlin's
  /// `LocalDateTime.toInstant(zone)`.
  ///
  /// A local time the clocks skip moves forward by the length of the gap.
  /// A local time they pass twice takes [preferredOffset] when it is one of
  /// the two, else the offset [resolution] chooses.
  ///
  /// Throws a [DateTimeArithmeticException] for a skipped or repeated time
  /// under [ZoneResolution.strict] without a fitting [preferredOffset].
  Instant toInstant(
    LocalDateTime local, {
    ZoneResolution resolution = ZoneResolution.earlierOffset,
    UtcOffset? preferredOffset,
  }) {
    final ZoneOffsetInfo info = offsetInfo(local);
    switch (info) {
      case RegularOffsetInfo(:final UtcOffset offset):
        return local.toInstantAt(offset);
      case GapOffsetInfo(:final ZoneTransition transition):
        if (resolution == ZoneResolution.strict) {
          throw DateTimeArithmeticException(
            '$local does not exist in $id: the clocks skip it',
          );
        }
        return local.toInstantAt(transition.offsetBefore);
      case OverlapOffsetInfo(:final ZoneTransition transition):
        if (preferredOffset == transition.offsetBefore ||
            preferredOffset == transition.offsetAfter) {
          return local.toInstantAt(preferredOffset!);
        }
        return switch (resolution) {
          ZoneResolution.earlierOffset => local.toInstantAt(
            transition.offsetBefore,
          ),
          ZoneResolution.laterOffset => local.toInstantAt(
            transition.offsetAfter,
          ),
          ZoneResolution.strict => throw DateTimeArithmeticException(
            '$local is ambiguous in $id: the clocks pass it twice',
          ),
        };
    }
  }

  /// The first moment of [date] in the zone: midnight, or the moment the
  /// clocks skip to when they skip midnight, Kotlin's `atStartOfDayIn`.
  Instant startOfDay(LocalDate date) {
    final local = LocalDateTime(date, LocalTime.midnight);
    final ZoneOffsetInfo info = offsetInfo(local);
    return switch (info) {
      GapOffsetInfo(:final ZoneTransition transition) => transition.instant,
      RegularOffsetInfo() || OverlapOffsetInfo() => toInstant(local),
    };
  }

  /// Whether [other] is a zone of the same identifier.
  @override
  bool operator ==(Object other) => other is TimeZone && other.id == id;

  /// A hash of the identifier.
  @override
  int get hashCode => id.hashCode;

  /// The identifier.
  @override
  String toString() => id;
}

/// A time zone whose offset never changes, Kotlin's
/// `kotlinx.datetime.FixedOffsetTimeZone`.
final class FixedOffsetTimeZone extends TimeZone {
  /// The zone that always has [offset], named [id] or after the offset.
  factory FixedOffsetTimeZone(UtcOffset offset, {String? id}) =>
      FixedOffsetTimeZone._(offset, id ?? offset.toString());

  /// Creates the zone of [offset] named [id].
  const FixedOffsetTimeZone._(this.offset, String id) : super._(id);

  /// The offset of the zone.
  final UtcOffset offset;

  /// The rules of the zone: one offset forever.
  @override
  ZoneRules get rules => ZoneRules.fixed(offset);

  /// The offset, at any moment.
  @override
  UtcOffset offsetAt(Instant instant) => offset;

  /// One offset, for any local time.
  @override
  ZoneOffsetInfo offsetInfo(LocalDateTime local) => RegularOffsetInfo(offset);
}

/// A time zone of rules from the database or from elsewhere.
final class _RuleTimeZone extends TimeZone {
  /// The zone of [id] that follows [rules].
  const _RuleTimeZone(super.id, this.rules) : super._();

  /// The offsets of the zone over time.
  @override
  final ZoneRules rules;
}
