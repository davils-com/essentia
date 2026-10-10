/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/recurrence/recurrence_frequency.dart';
import 'package:essentia/src/recurrence/recurrence_until.dart';
import 'package:essentia/src/recurrence/recurrence_violation_codes.dart';
import 'package:essentia/src/recurrence/recurrence_weekday.dart';
import 'package:essentia/src/time/day_of_week.dart';
import 'package:essentia/src/validation/validatable.dart';
import 'package:essentia/src/validation/validatable_checks.dart';
import 'package:essentia/src/validation/validation_scope.dart';
import 'package:meta/meta.dart';

/// A rule by which a date or time repeats, the `RRULE` of RFC 5545:
/// "every second Tuesday of the month", "every weekday until the end of
/// the year".
///
/// A rule says how often it repeats ([frequency] and [interval]), how
/// long ([count] or [until]), and on which seconds, minutes, hours,
/// weekdays, days of the month or year, weeks and months, each a `BY`
/// part that expands or limits the repetitions as RFC 5545 tells.
/// [bySetPosition] then picks among the repetitions of each period.
///
/// A rule is checked when it is made and throws a `ValidationException`
/// that lists everything wrong with it. A `RecurrenceSet` expands it from
/// a start.
@immutable
final class RecurrenceRule implements Validatable {
  /// The rule of the given parts.
  ///
  /// Throws a `ValidationException` that lists every part that breaks
  /// RFC 5545.
  factory RecurrenceRule({
    required RecurrenceFrequency frequency,
    int interval = 1,
    int? count,
    RecurrenceUntil? until,
    List<int> bySecond = const <int>[],
    List<int> byMinute = const <int>[],
    List<int> byHour = const <int>[],
    List<RecurrenceWeekday> byDay = const <RecurrenceWeekday>[],
    List<int> byMonthDay = const <int>[],
    List<int> byYearDay = const <int>[],
    List<int> byWeekNumber = const <int>[],
    List<int> byMonth = const <int>[],
    List<int> bySetPosition = const <int>[],
    DayOfWeek weekStart = DayOfWeek.monday,
  }) => RecurrenceRule.assembled(
    frequency: frequency,
    interval: interval,
    count: count,
    until: until,
    bySecond: bySecond,
    byMinute: byMinute,
    byHour: byHour,
    byDay: byDay,
    byMonthDay: byMonthDay,
    byYearDay: byYearDay,
    byWeekNumber: byWeekNumber,
    byMonth: byMonth,
    bySetPosition: bySetPosition,
    weekStart: weekStart,
  ).validateOrThrow(_subject);

  /// Puts a rule together from its parts without checking them.
  ///
  /// Only the builder uses this, because it checks as part of its own
  /// report.
  @internal
  factory RecurrenceRule.assembled({
    required RecurrenceFrequency frequency,
    required int interval,
    required int? count,
    required RecurrenceUntil? until,
    required List<int> bySecond,
    required List<int> byMinute,
    required List<int> byHour,
    required List<RecurrenceWeekday> byDay,
    required List<int> byMonthDay,
    required List<int> byYearDay,
    required List<int> byWeekNumber,
    required List<int> byMonth,
    required List<int> bySetPosition,
    required DayOfWeek weekStart,
  }) => RecurrenceRule._(
    frequency,
    interval,
    count,
    until,
    _sorted(bySecond),
    _sorted(byMinute),
    _sorted(byHour),
    List<RecurrenceWeekday>.unmodifiable(byDay),
    _sorted(byMonthDay),
    _sorted(byYearDay),
    _sorted(byWeekNumber),
    _sorted(byMonth),
    _sorted(bySetPosition),
    weekStart,
  );

  /// Reads a rule as RFC 5545 writes it, such as
  /// `FREQ=MONTHLY;BYDAY=2TU;COUNT=10`, with or without `RRULE:` before.
  ///
  /// Throws a [FormatException] for text that is no rule, and a
  /// `ValidationException` for a rule that breaks RFC 5545.
  factory RecurrenceRule.parse(String text) {
    final String body = text.trim().toUpperCase().startsWith('RRULE:')
        ? text.trim().substring(6)
        : text.trim();
    final parts = <String, String>{};
    for (final String part in body.split(';')) {
      if (part.isEmpty) {
        continue;
      }
      final int equals = part.indexOf('=');
      if (equals <= 0) {
        throw FormatException('Not a rule part', text);
      }
      parts[part.substring(0, equals).toUpperCase()] = part.substring(
        equals + 1,
      );
    }
    final RecurrenceFrequency? frequency = RecurrenceFrequency.ofToken(
      parts['FREQ'] ?? '',
    );
    if (frequency == null) {
      throw FormatException('A rule needs a frequency', text);
    }
    List<int> numbers(String name) => <int>[
      for (final String value in (parts[name] ?? '').split(','))
        if (value.isNotEmpty) _number(value, text),
    ];
    final String? count = parts['COUNT'];
    final String? until = parts['UNTIL'];
    final String? weekStart = parts['WKST'];
    return RecurrenceRule(
      frequency: frequency,
      interval: parts['INTERVAL'] == null
          ? 1
          : _number(parts['INTERVAL']!, text),
      count: count == null ? null : _number(count, text),
      until: until == null ? null : RecurrenceUntil.parse(until),
      bySecond: numbers('BYSECOND'),
      byMinute: numbers('BYMINUTE'),
      byHour: numbers('BYHOUR'),
      byDay: <RecurrenceWeekday>[
        for (final String value in (parts['BYDAY'] ?? '').split(','))
          if (value.isNotEmpty) RecurrenceWeekday.parse(value),
      ],
      byMonthDay: numbers('BYMONTHDAY'),
      byYearDay: numbers('BYYEARDAY'),
      byWeekNumber: numbers('BYWEEKNO'),
      byMonth: numbers('BYMONTH'),
      bySetPosition: numbers('BYSETPOS'),
      weekStart: weekStart == null
          ? DayOfWeek.monday
          : RecurrenceWeekday.parse(weekStart).day,
    );
  }

  /// Creates the rule of the given parts, without checking them.
  const RecurrenceRule._(
    this.frequency,
    this.interval,
    this.count,
    this.until,
    this.bySecond,
    this.byMinute,
    this.byHour,
    this.byDay,
    this.byMonthDay,
    this.byYearDay,
    this.byWeekNumber,
    this.byMonth,
    this.bySetPosition,
    this.weekStart,
  );

  /// What a rule is called in a validation report.
  static const _subject = 'recurrence rule';

  /// [values] sorted, without repeats and unmodifiable.
  static List<int> _sorted(List<int> values) =>
      List<int>.unmodifiable(values.toSet().toList()..sort());

  /// [value] as a number, or a [FormatException] naming [text].
  static int _number(String value, String text) {
    final int? number = int.tryParse(value);
    if (number == null) {
      throw FormatException('Not a number: $value', text);
    }
    return number;
  }

  /// How often the rule repeats.
  final RecurrenceFrequency frequency;

  /// Every how many periods the rule repeats, 1 for every one.
  final int interval;

  /// How many times the rule repeats in all, the start included, or `null`.
  final int? count;

  /// The last moment the rule repeats at, or `null`.
  final RecurrenceUntil? until;

  /// The seconds of the minute, from 0 to 59.
  final List<int> bySecond;

  /// The minutes of the hour, from 0 to 59.
  final List<int> byMinute;

  /// The hours of the day, from 0 to 23.
  final List<int> byHour;

  /// The weekdays, each with an ordinal or not.
  final List<RecurrenceWeekday> byDay;

  /// The days of the month, from 1 or from the end with -1.
  final List<int> byMonthDay;

  /// The days of the year, from 1 or from the end with -1.
  final List<int> byYearDay;

  /// The weeks of the year, from 1 or from the end with -1.
  final List<int> byWeekNumber;

  /// The months, from 1 to 12.
  final List<int> byMonth;

  /// Which of the repetitions of each period to keep, from 1 or from the
  /// end with -1.
  final List<int> bySetPosition;

  /// The day a week starts on, which matters to weekly rules and to week
  /// numbers.
  final DayOfWeek weekStart;

  /// Whether the rule repeats without end.
  bool get isInfinite => count == null && until == null;

  /// The rule with the given parts replaced; `clearCount` and `clearUntil`
  /// remove those.
  ///
  /// Throws a `ValidationException` when the result breaks RFC 5545.
  RecurrenceRule copyWith({
    RecurrenceFrequency? frequency,
    int? interval,
    int? count,
    bool clearCount = false,
    RecurrenceUntil? until,
    bool clearUntil = false,
    List<int>? bySecond,
    List<int>? byMinute,
    List<int>? byHour,
    List<RecurrenceWeekday>? byDay,
    List<int>? byMonthDay,
    List<int>? byYearDay,
    List<int>? byWeekNumber,
    List<int>? byMonth,
    List<int>? bySetPosition,
    DayOfWeek? weekStart,
  }) => RecurrenceRule(
    frequency: frequency ?? this.frequency,
    interval: interval ?? this.interval,
    count: clearCount ? null : count ?? this.count,
    until: clearUntil ? null : until ?? this.until,
    bySecond: bySecond ?? this.bySecond,
    byMinute: byMinute ?? this.byMinute,
    byHour: byHour ?? this.byHour,
    byDay: byDay ?? this.byDay,
    byMonthDay: byMonthDay ?? this.byMonthDay,
    byYearDay: byYearDay ?? this.byYearDay,
    byWeekNumber: byWeekNumber ?? this.byWeekNumber,
    byMonth: byMonth ?? this.byMonth,
    bySetPosition: bySetPosition ?? this.bySetPosition,
    weekStart: weekStart ?? this.weekStart,
  );

  /// Checks the rule against RFC 5545 and reports every problem.
  @override
  void validate(ValidationScope scope) {
    if (interval < 1) {
      scope.fail(
        'must be at least 1',
        property: 'interval',
        code: RecurrenceViolationCodes.interval,
      );
    }
    final int? times = count;
    if (times != null && times < 1) {
      scope.fail(
        'must be at least 1',
        property: 'count',
        code: RecurrenceViolationCodes.count,
      );
    }
    if (times != null && until != null) {
      scope.fail(
        'a rule ends either after a count or at an end, not both',
        property: 'until',
        code: RecurrenceViolationCodes.countAndUntil,
      );
    }
    _range(scope, 'bySecond', bySecond, 0, 59);
    _range(scope, 'byMinute', byMinute, 0, 59);
    _range(scope, 'byHour', byHour, 0, 23);
    _signedRange(scope, 'byMonthDay', byMonthDay, 31);
    _signedRange(scope, 'byYearDay', byYearDay, 366);
    _signedRange(scope, 'byWeekNumber', byWeekNumber, 53);
    _range(scope, 'byMonth', byMonth, 1, 12);
    _signedRange(scope, 'bySetPosition', bySetPosition, 366);
    _applicability(scope);
    _ordinals(scope);
    final bool selects =
        bySecond.isNotEmpty ||
        byMinute.isNotEmpty ||
        byHour.isNotEmpty ||
        byDay.isNotEmpty ||
        byMonthDay.isNotEmpty ||
        byYearDay.isNotEmpty ||
        byWeekNumber.isNotEmpty ||
        byMonth.isNotEmpty;
    if (bySetPosition.isNotEmpty && !selects) {
      scope.fail(
        'needs another BY part to select from',
        property: 'bySetPosition',
        code: RecurrenceViolationCodes.setPositionAlone,
      );
    }
  }

  /// Reports values of [values] outside [low] to [high].
  static void _range(
    ValidationScope scope,
    String property,
    List<int> values,
    int low,
    int high,
  ) {
    for (final value in values) {
      if (value < low || value > high) {
        scope.fail(
          '$value lies outside $low to $high',
          property: property,
          code: RecurrenceViolationCodes.outOfRange,
        );
      }
    }
  }

  /// Reports values of [values] that are 0 or beyond [limit] either way.
  static void _signedRange(
    ValidationScope scope,
    String property,
    List<int> values,
    int limit,
  ) {
    for (final value in values) {
      if (value == 0 || value.abs() > limit) {
        scope.fail(
          '$value lies outside 1 to $limit either way',
          property: property,
          code: RecurrenceViolationCodes.outOfRange,
        );
      }
    }
  }

  /// Reports `BY` parts that do not apply to [frequency].
  void _applicability(ValidationScope scope) {
    void refuse(String property) => scope.fail(
      'does not apply to a ${frequency.token} rule',
      property: property,
      code: RecurrenceViolationCodes.notApplicable,
    );
    if (byWeekNumber.isNotEmpty && frequency != RecurrenceFrequency.yearly) {
      refuse('byWeekNumber');
    }
    final bool dayToMonth =
        frequency == RecurrenceFrequency.daily ||
        frequency == RecurrenceFrequency.weekly ||
        frequency == RecurrenceFrequency.monthly;
    if (byYearDay.isNotEmpty && dayToMonth) {
      refuse('byYearDay');
    }
    if (byMonthDay.isNotEmpty && frequency == RecurrenceFrequency.weekly) {
      refuse('byMonthDay');
    }
  }

  /// Reports ordinals of [byDay] where RFC 5545 allows none.
  void _ordinals(ValidationScope scope) {
    final bool allowed =
        (frequency == RecurrenceFrequency.monthly ||
            frequency == RecurrenceFrequency.yearly) &&
        byWeekNumber.isEmpty;
    for (final RecurrenceWeekday day in byDay) {
      final int? ordinal = day.ordinal;
      if (ordinal == null) {
        continue;
      }
      if (!allowed) {
        scope.fail(
          '$day has an ordinal, which only a monthly or yearly rule '
          'without week numbers may have',
          property: 'byDay',
          code: RecurrenceViolationCodes.ordinal,
        );
        continue;
      }
      if (ordinal == 0 || ordinal.abs() > 53) {
        scope.fail(
          '$day has an ordinal outside 1 to 53 either way',
          property: 'byDay',
          code: RecurrenceViolationCodes.outOfRange,
        );
      }
    }
  }

  /// Whether [other] is the same rule.
  @override
  bool operator ==(Object other) =>
      other is RecurrenceRule && other.toString() == toString();

  /// A hash of the rule.
  @override
  int get hashCode => toString().hashCode;

  /// The rule as RFC 5545 writes it, its parts in a fixed order:
  /// `FREQ=WEEKLY;COUNT=10;INTERVAL=2;BYDAY=MO,WE`.
  @override
  String toString() {
    final parts = <String>['FREQ=${frequency.token}'];
    final RecurrenceUntil? end = until;
    if (end != null) {
      parts.add('UNTIL=${end.text}');
    }
    if (count != null) {
      parts.add('COUNT=$count');
    }
    if (interval != 1) {
      parts.add('INTERVAL=$interval');
    }
    void add(String name, List<Object> values) {
      if (values.isNotEmpty) {
        parts.add('$name=${values.join(',')}');
      }
    }

    add('BYSECOND', bySecond);
    add('BYMINUTE', byMinute);
    add('BYHOUR', byHour);
    add('BYDAY', byDay);
    add('BYMONTHDAY', byMonthDay);
    add('BYYEARDAY', byYearDay);
    add('BYWEEKNO', byWeekNumber);
    add('BYMONTH', byMonth);
    add('BYSETPOS', bySetPosition);
    if (weekStart != DayOfWeek.monday) {
      parts.add('WKST=${RecurrenceWeekday.tokenOf(weekStart)}');
    }
    return parts.join(';');
  }
}
