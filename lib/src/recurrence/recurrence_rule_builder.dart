/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/dsl/validating_builder.dart';
import 'package:essentia/src/recurrence/recurrence_frequency.dart';
import 'package:essentia/src/recurrence/recurrence_rule.dart';
import 'package:essentia/src/recurrence/recurrence_until.dart';
import 'package:essentia/src/recurrence/recurrence_weekday.dart';
import 'package:essentia/src/time/day_of_week.dart';
import 'package:meta/meta.dart';

/// Builds a `RecurrenceRule` part by part, for `recurrenceRule`.
///
/// ```dart
/// final RecurrenceRule rule = recurrenceRule((it) {
///   it.frequency = RecurrenceFrequency.monthly;
///   it.weekday(DayOfWeek.tuesday, 2);
///   it.count = 10;
/// });
/// ```
final class RecurrenceRuleBuilder extends ValidatingBuilder<RecurrenceRule> {
  /// How often the rule repeats, daily unless set.
  RecurrenceFrequency frequency = RecurrenceFrequency.daily;

  /// Every how many periods the rule repeats.
  var interval = 1;

  /// How many times the rule repeats in all, or `null`.
  int? count;

  /// The last moment the rule repeats at, or `null`.
  RecurrenceUntil? until;

  /// The seconds of the minute.
  var bySecond = <int>[];

  /// The minutes of the hour.
  var byMinute = <int>[];

  /// The hours of the day.
  var byHour = <int>[];

  /// The weekdays; [weekday] adds one.
  var byDay = <RecurrenceWeekday>[];

  /// The days of the month.
  var byMonthDay = <int>[];

  /// The days of the year.
  var byYearDay = <int>[];

  /// The weeks of the year.
  var byWeekNumber = <int>[];

  /// The months.
  var byMonth = <int>[];

  /// Which repetitions of each period to keep.
  var bySetPosition = <int>[];

  /// The day a week starts on.
  DayOfWeek weekStart = DayOfWeek.monday;

  /// What is being built.
  @override
  @protected
  String get subject => 'recurrence rule';

  /// Adds [day] to the weekdays, every one or only the [ordinal]th.
  void weekday(DayOfWeek day, [int? ordinal]) {
    byDay.add(RecurrenceWeekday(day, ordinal));
  }

  /// Puts the rule together without checking it.
  @override
  @protected
  RecurrenceRule assemble() => RecurrenceRule.assembled(
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
  );
}
