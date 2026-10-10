/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/icalendar/ics_property.dart';
import 'package:essentia/src/icalendar/ics_time_zone_observance.dart';
import 'package:essentia/src/icalendar/internal/ics_equality.dart';
import 'package:essentia/src/recurrence/recurrence_anchor.dart';
import 'package:essentia/src/recurrence/recurrence_frequency.dart';
import 'package:essentia/src/recurrence/recurrence_occurrence.dart';
import 'package:essentia/src/recurrence/recurrence_rule.dart';
import 'package:essentia/src/recurrence/recurrence_set.dart';
import 'package:essentia/src/recurrence/recurrence_weekday.dart';
import 'package:essentia/src/time/day_of_week.dart';
import 'package:essentia/src/time/instant.dart';
import 'package:essentia/src/time/local_date_time.dart';
import 'package:essentia/src/time/month.dart';
import 'package:essentia/src/time/recurring_zone_rule.dart';
import 'package:essentia/src/time/time_zone.dart';
import 'package:essentia/src/time/utc_offset.dart';
import 'package:essentia/src/time/zone_rules.dart';
import 'package:essentia/src/time/zone_transition.dart';
import 'package:essentia/src/time/zone_transition_rule.dart';
import 'package:meta/meta.dart';

/// A time zone an iCalendar file describes, the `VTIMEZONE` of RFC 5545:
/// its [id] and the [observances] of its standard and daylight time.
///
/// [toZoneRules] turns it into rules a `TimeZone` follows, and
/// [IcsTimeZone.fromTimeZone] writes a zone of the time zone database as
/// one.
@immutable
final class IcsTimeZone {
  /// The zone [id] of [observances].
  IcsTimeZone({
    required this.id,
    required List<IcsTimeZoneObservance> observances,
    List<IcsProperty> properties = const <IcsProperty>[],
  }) : observances = List<IcsTimeZoneObservance>.unmodifiable(observances),
       properties = List<IcsProperty>.unmodifiable(properties);

  /// The zone [zone] as it behaves from [from] up to [until], with a year
  /// of margin on both sides: its shifts there, and the rules of its
  /// recurring shifts so later repetitions find their offsets too.
  factory IcsTimeZone.fromTimeZone(
    TimeZone zone, {
    required Instant from,
    required Instant until,
  }) {
    final ZoneRules rules = zone.rules;
    final Instant start = from - const Duration(days: 366);
    final Instant end = until + const Duration(days: 366);
    final RecurringZoneRule? recurring = rules.recurring;
    final Instant? historyEnd = rules.transitions.isEmpty
        ? null
        : rules.transitions.last.instant;
    final Instant explicitEnd = recurring == null || historyEnd == null
        ? end
        : (historyEnd.isBefore(end)
              ? historyEnd + const Duration(seconds: 1)
              : end);
    final List<ZoneTransition> explicit =
        recurring != null && historyEnd == null
        ? const <ZoneTransition>[]
        : rules.transitionsBetween(start, explicitEnd);
    final observances = <IcsTimeZoneObservance>[
      for (final ZoneTransition transition in explicit)
        IcsTimeZoneObservance(
          daylight: transition.isGap,
          start: _wallOf(transition),
          offsetFrom: transition.offsetBefore,
          offsetTo: transition.offsetAfter,
        ),
    ];
    final Instant recurringFrom =
        historyEnd != null && historyEnd.isAfter(start) ? historyEnd : start;
    if (recurring != null && recurringFrom.isBefore(end)) {
      observances.addAll(_recurringObservances(recurring, recurringFrom));
    }
    if (observances.isEmpty) {
      final UtcOffset offset = zone.offsetAt(from);
      observances.add(
        IcsTimeZoneObservance(
          daylight: false,
          start: LocalDateTime.of(1970, 1, 1, 0, 0),
          offsetFrom: offset,
          offsetTo: offset,
        ),
      );
    }
    return IcsTimeZone(id: zone.id, observances: observances);
  }

  /// The identifier, `TZID`.
  final String id;

  /// The standard and daylight parts.
  final List<IcsTimeZoneObservance> observances;

  /// The properties this library does not read, as written.
  final List<IcsProperty> properties;

  /// The last year whose shifts are listed one by one when no recurring
  /// rule takes over.
  static const _horizon = 2100;

  /// The rules of the zone: every shift of every observance in time order,
  /// and the yearly rules of observances that repeat for ever, where they
  /// are of the usual kind, "the nth or last weekday of a month".
  ZoneRules toZoneRules() {
    if (observances.isEmpty) {
      return ZoneRules.fixed(UtcOffset.zero);
    }
    final forever = <IcsTimeZoneObservance>[
      for (final observance in observances)
        if (observance.rules.any((rule) => rule.isInfinite)) observance,
    ];
    final List<ZoneTransitionRule>? yearly = _yearlyRules(forever);
    final int lastYear = yearly == null
        ? _horizon
        : observances
                  .map((it) => it.start.year)
                  .reduce((a, b) => a > b ? a : b) +
              1;
    final changes = <(Instant, UtcOffset)>[];
    for (final IcsTimeZoneObservance observance in observances) {
      final set = RecurrenceSet(
        FloatingAnchor(observance.start),
        rules: observance.rules,
        dates: observance.dates,
      );
      for (final RecurrenceOccurrence occurrence in set.occurrences()) {
        if (occurrence.local.year > lastYear) {
          break;
        }
        changes.add((
          occurrence.local.toInstantAt(observance.offsetFrom),
          observance.offsetTo,
        ));
      }
    }
    changes.sort(
      ((Instant, UtcOffset) a, (Instant, UtcOffset) b) => a.$1.compareTo(b.$1),
    );
    final IcsTimeZoneObservance earliest = observances.reduce(
      (a, b) => a.start.isAfter(b.start) ? b : a,
    );
    final transitions = <ZoneTransition>[];
    UtcOffset offset = earliest.offsetFrom;
    for (final (Instant at, UtcOffset next) in changes) {
      if (next == offset ||
          (transitions.isNotEmpty && !at.isAfter(transitions.last.instant))) {
        continue;
      }
      transitions.add(ZoneTransition(at, offset, next));
      offset = next;
    }
    final IcsTimeZoneObservance? standard = forever
        .where((it) => !it.daylight)
        .firstOrNull;
    return ZoneRules(
      initialOffset: earliest.offsetFrom,
      transitions: transitions,
      recurring: yearly == null || yearly.isEmpty
          ? null
          : RecurringZoneRule(
              standardOffset: standard?.offsetTo ?? forever.first.offsetTo,
              rules: yearly,
            ),
    );
  }

  /// The yearly rules of the observances that repeat for ever, or `null`
  /// when one of them is not of the usual kind.
  static List<ZoneTransitionRule>? _yearlyRules(
    List<IcsTimeZoneObservance> forever,
  ) {
    final rules = <ZoneTransitionRule>[];
    for (final observance in forever) {
      for (final RecurrenceRule rule in observance.rules) {
        if (!rule.isInfinite) {
          continue;
        }
        final ZoneTransitionRule? yearly = _yearlyRule(rule, observance);
        if (yearly == null) {
          return null;
        }
        rules.add(yearly);
      }
    }
    return rules;
  }

  /// The yearly rule [rule] of [observance] stands for, or `null`.
  static ZoneTransitionRule? _yearlyRule(
    RecurrenceRule rule,
    IcsTimeZoneObservance observance,
  ) {
    final bool plain =
        rule.frequency == RecurrenceFrequency.yearly &&
        rule.interval == 1 &&
        rule.byMonth.length == 1 &&
        rule.bySetPosition.isEmpty &&
        rule.byYearDay.isEmpty &&
        rule.byWeekNumber.isEmpty &&
        rule.byHour.isEmpty &&
        rule.byMinute.isEmpty &&
        rule.bySecond.isEmpty;
    if (!plain) {
      return null;
    }
    final Month month = Month.of(rule.byMonth.single);
    final time = Duration(seconds: observance.start.time.toSecondOfDay());
    ZoneTransitionRule make(
      int day, {
      ({DayOfWeek day, bool onOrBefore})? pick,
    }) => ZoneTransitionRule(
      month: month,
      day: day,
      dayOfWeek: pick?.day,
      onOrBefore: pick?.onOrBefore ?? false,
      timeOfDay: time,
      offsetAfter: observance.offsetTo,
    );
    if (rule.byDay.isEmpty && rule.byMonthDay.length == 1) {
      return make(rule.byMonthDay.single);
    }
    if (rule.byDay.length != 1) {
      return null;
    }
    final RecurrenceWeekday weekday = rule.byDay.single;
    final int? ordinal = weekday.ordinal;
    if (ordinal != null && rule.byMonthDay.isEmpty) {
      return ordinal > 0
          ? make(
              1 + 7 * (ordinal - 1),
              pick: (day: weekday.day, onOrBefore: false),
            )
          : make(
              -1 - 7 * (-ordinal - 1),
              pick: (day: weekday.day, onOrBefore: true),
            );
    }
    final List<int> days = rule.byMonthDay;
    final bool week =
        ordinal == null &&
        days.length == 7 &&
        days.last - days.first == 6 &&
        days.first > 0;
    if (!week) {
      return null;
    }
    return make(days.first, pick: (day: weekday.day, onOrBefore: false));
  }

  /// The observances of the yearly rules of [recurring], each starting
  /// with its first shift after [after].
  static List<IcsTimeZoneObservance> _recurringObservances(
    RecurringZoneRule recurring,
    Instant after,
  ) {
    final int year = TimeZone.utc.toLocalDateTime(after).year;
    final List<ZoneTransition> shifts = <ZoneTransition>[
      for (var offset = 0; offset < 3; offset += 1)
        ...recurring.transitionsIn(year + offset),
    ].where((it) => it.instant.isAfter(after)).toList();
    return <IcsTimeZoneObservance>[
      for (final ZoneTransitionRule rule in recurring.rules)
        for (final ZoneTransition shift
            in shifts.where((it) => it.offsetAfter == rule.offsetAfter).take(1))
          IcsTimeZoneObservance(
            daylight:
                rule.offsetAfter.totalSeconds >
                recurring.standardOffset.totalSeconds,
            start: _wallOf(shift),
            offsetFrom: shift.offsetBefore,
            offsetTo: shift.offsetAfter,
            rules: <RecurrenceRule>[_ruleOf(rule)],
          ),
    ];
  }

  /// The yearly recurrence rule of [rule].
  static RecurrenceRule _ruleOf(ZoneTransitionRule rule) {
    final DayOfWeek? weekday = rule.dayOfWeek;
    if (weekday == null) {
      return RecurrenceRule(
        frequency: RecurrenceFrequency.yearly,
        byMonth: <int>[rule.month.number],
        byMonthDay: <int>[rule.day],
      );
    }
    final int day = rule.day;
    if (!rule.onOrBefore && day > 0 && (day - 1) % 7 == 0) {
      return RecurrenceRule(
        frequency: RecurrenceFrequency.yearly,
        byMonth: <int>[rule.month.number],
        byDay: <RecurrenceWeekday>[
          RecurrenceWeekday(weekday, (day - 1) ~/ 7 + 1),
        ],
      );
    }
    if (rule.onOrBefore && day < 0 && (-day - 1) % 7 == 0) {
      return RecurrenceRule(
        frequency: RecurrenceFrequency.yearly,
        byMonth: <int>[rule.month.number],
        byDay: <RecurrenceWeekday>[
          RecurrenceWeekday(weekday, -((-day - 1) ~/ 7 + 1)),
        ],
      );
    }
    final int first = rule.onOrBefore ? day - 6 : day;
    return RecurrenceRule(
      frequency: RecurrenceFrequency.yearly,
      byMonth: <int>[rule.month.number],
      byDay: <RecurrenceWeekday>[RecurrenceWeekday(weekday)],
      byMonthDay: <int>[
        for (var offset = 0; offset < 7; offset += 1)
          if (first + offset >= 1 && first + offset <= 31) first + offset,
      ],
    );
  }

  /// The local time of [transition] on the clocks before it.
  static LocalDateTime _wallOf(ZoneTransition transition) =>
      FixedOffsetTimeZone(transition.offsetBefore)
          .toLocalDateTime(transition.instant);

  /// Whether [other] describes the zone the same way.
  @override
  bool operator ==(Object other) =>
      other is IcsTimeZone &&
      other.id == id &&
      sameIcsValues(
        <Object?>[other.observances, other.properties],
        <Object?>[observances, properties],
      );

  /// A hash of the zone.
  @override
  int get hashCode => hashIcsValues(<Object?>[id, observances, properties]);

  /// Describes the zone.
  @override
  String toString() => 'IcsTimeZone($id, ${observances.length} observances)';
}
