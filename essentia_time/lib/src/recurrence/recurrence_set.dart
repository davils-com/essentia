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
import 'package:essentia_time/src/date/local_time.dart';
import 'package:essentia_time/src/instant.dart';
import 'package:essentia_time/src/internal/time_math.dart';
import 'package:essentia_time/src/recurrence/internal/rule_expansion.dart';
import 'package:essentia_time/src/recurrence/recurrence_anchor.dart';
import 'package:essentia_time/src/recurrence/recurrence_frequency.dart';
import 'package:essentia_time/src/recurrence/recurrence_occurrence.dart';
import 'package:essentia_time/src/recurrence/recurrence_rule.dart';
import 'package:essentia_time/src/recurrence/recurrence_until.dart';
import 'package:essentia_time/src/recurrence/recurrence_weekday.dart';
import 'package:essentia_time/src/zone/time_zone.dart';
import 'package:meta/meta.dart';

/// Every repetition of something that recurs, RFC 5545's recurrence set:
/// the [anchor] it starts at, the [rules] it repeats by, the extra
/// [dates] it also happens on and the [exceptions] it skips.
///
/// ```dart
/// final weekly = RecurrenceSet(
///   ZonedAnchor(LocalDateTime.of(2026, 10, 5, 9, 0), berlin),
///   rules: <RecurrenceRule>[
///     RecurrenceRule.parse('FREQ=WEEKLY;BYDAY=MO,WE;COUNT=6'),
///   ],
///   exceptions: <LocalDateTime>[LocalDateTime.of(2026, 10, 7, 9, 0)],
/// );
/// final next = weekly.occurrencesBetween(
///   LocalDateTime.of(2026, 10, 1, 0, 0),
///   LocalDateTime.of(2026, 11, 1, 0, 0),
/// );
/// ```
///
/// The anchor is always the first repetition, and it counts towards the
/// `COUNT` of a rule even when the rule would not produce it, as RFC 5545
/// asks. Repetitions are read on the local clock of the anchor and come out
/// in time order, each once; the exceptions match them by local time.
/// Everything is computed lazily, so a rule without end costs only what is
/// read of it.
@immutable
final class RecurrenceSet {
  /// The repetitions from [anchor] by [rules] and on [dates], without
  /// [exceptions].
  ///
  /// Throws an [ArgumentError] when a rule of whole days repeats within a
  /// day or picks hours, minutes or seconds.
  RecurrenceSet(
    this.anchor, {
    List<RecurrenceRule> rules = const <RecurrenceRule>[],
    List<LocalDateTime> dates = const <LocalDateTime>[],
    List<LocalDateTime> exceptions = const <LocalDateTime>[],
  }) : rules = List<RecurrenceRule>.unmodifiable(rules),
       dates = List<LocalDateTime>.unmodifiable(dates.toSet().toList()..sort()),
       exceptions = Set<LocalDateTime>.unmodifiable(exceptions) {
    if (anchor is! DateAnchor) {
      return;
    }
    for (final rule in rules) {
      if (rule.frequency.isTimeBased ||
          rule.byHour.isNotEmpty ||
          rule.byMinute.isNotEmpty ||
          rule.bySecond.isNotEmpty) {
        throw ArgumentError.value(
          rule,
          'rules',
          'A recurrence of whole days cannot repeat within a day',
        );
      }
    }
  }

  /// Where the repetitions start, the first of them.
  final RecurrenceAnchor anchor;

  /// The rules the repetitions follow.
  final List<RecurrenceRule> rules;

  /// The extra local times of repetitions, in time order.
  final List<LocalDateTime> dates;

  /// The local times of repetitions that are left out.
  final Set<LocalDateTime> exceptions;

  /// Whether the repetitions go on without end.
  bool get isInfinite => rules.any((rule) => rule.isInfinite);

  /// Whether there is only the anchor and the extra dates.
  bool get isSingle => rules.isEmpty && dates.isEmpty;

  /// The repetitions in time order, from [from] on when given, lazily.
  Iterable<RecurrenceOccurrence> occurrences({LocalDateTime? from}) sync* {
    final streams = <Iterator<LocalDateTime>>[
      <LocalDateTime>[anchor.local].iterator,
      dates.iterator,
      for (final RecurrenceRule rule in rules)
        expandRule(
          rule,
          anchor.local,
          dateOnly: anchor is DateAnchor,
          zone: anchor.zone,
          from: from,
        ).iterator,
    ];
    final List<LocalDateTime?> heads = streams
        .map((stream) => stream.moveNext() ? stream.current : null)
        .toList();
    LocalDateTime? previous;
    while (true) {
      var smallest = -1;
      for (var index = 0; index < heads.length; index += 1) {
        final LocalDateTime? head = heads[index];
        if (head == null) {
          continue;
        }
        if (smallest < 0 || head.isBefore(heads[smallest]!)) {
          smallest = index;
        }
      }
      if (smallest < 0) {
        return;
      }
      final LocalDateTime local = heads[smallest]!;
      final Iterator<LocalDateTime> stream = streams[smallest];
      heads[smallest] = stream.moveNext() ? stream.current : null;
      if (local == previous) {
        continue;
      }
      previous = local;
      if (exceptions.contains(local) ||
          (from != null && local.isBefore(from))) {
        continue;
      }
      yield RecurrenceOccurrence(local, anchor.instantOf(local));
    }
  }

  /// The repetitions that start before [until] and, lasting [duration],
  /// end after [from]: those a calendar shows between the two local times.
  ///
  /// Throws a [StateError] when more than [limit] repetitions fall in
  /// between, which guards against a rule that repeats every second over a
  /// year.
  List<RecurrenceOccurrence> occurrencesBetween(
    LocalDateTime from,
    LocalDateTime until, {
    Duration duration = Duration.zero,
    int limit = 100000,
  }) {
    final LocalDateTime earliest = _shift(from, -duration.inSeconds, 0);
    final result = <RecurrenceOccurrence>[];
    for (final RecurrenceOccurrence occurrence in occurrences(from: earliest)) {
      if (!occurrence.local.isBefore(until)) {
        break;
      }
      if (!_shift(occurrence.local, duration.inSeconds, 0).isAfter(from) &&
          duration > Duration.zero) {
        continue;
      }
      if (result.length >= limit) {
        throw StateError(
          'More than $limit repetitions between $from and $until',
        );
      }
      result.add(occurrence);
    }
    return result;
  }

  /// The repetitions that, lasting [duration], overlap the moments from
  /// [from] up to [until]; a floating recurrence is read in [floatingZone].
  ///
  /// Throws a [StateError] when more than [limit] repetitions fall in
  /// between.
  List<RecurrenceOccurrence> occurrencesOverlapping(
    Instant from,
    Instant until, {
    Duration duration = Duration.zero,
    TimeZone floatingZone = TimeZone.utc,
    int limit = 100000,
  }) {
    final TimeZone zone = anchor.zone ?? floatingZone;
    final result = <RecurrenceOccurrence>[];
    for (final RecurrenceOccurrence occurrence in occurrencesBetween(
      _shift(zone.toLocalDateTime(from), -secondsPerDay, 0),
      _shift(zone.toLocalDateTime(until), secondsPerDay, 0),
      duration: duration,
      limit: limit,
    )) {
      final Instant start = occurrence.instantIn(zone);
      final bool overlaps =
          start.isBefore(until) &&
          (duration == Duration.zero
              ? !start.isBefore(from)
              : (start + duration).isAfter(from));
      if (overlaps) {
        result.add(occurrence);
      }
    }
    return result;
  }

  /// The first repetition after [local], or `null`.
  RecurrenceOccurrence? firstAfter(LocalDateTime local) {
    for (final RecurrenceOccurrence occurrence in occurrences(from: local)) {
      if (occurrence.local.isAfter(local)) {
        return occurrence;
      }
    }
    return null;
  }

  /// The last repetition before [local], or `null`.
  RecurrenceOccurrence? lastBefore(LocalDateTime local) {
    RecurrenceOccurrence? found;
    var reach = 64;
    while (true) {
      final LocalDateTime from = _shift(local, -reach * secondsPerDay, 0);
      for (final RecurrenceOccurrence occurrence in occurrences(
        from: from.isBefore(anchor.local) ? null : from,
      )) {
        if (!occurrence.local.isBefore(local)) {
          break;
        }
        found = occurrence;
      }
      if (found != null || !from.isAfter(anchor.local)) {
        return found;
      }
      reach *= 4;
    }
  }

  /// Whether there is a repetition at [local].
  bool contains(LocalDateTime local) {
    for (final RecurrenceOccurrence occurrence in occurrences(from: local)) {
      return occurrence.local == local;
    }
    return false;
  }

  /// The repetitions up to but not including the one at [local]: every
  /// rule ends before it and later dates and exceptions are dropped, "this
  /// and following" cut off.
  RecurrenceSet truncatedBefore(LocalDateTime local) => RecurrenceSet(
    anchor,
    rules: <RecurrenceRule>[
      for (final RecurrenceRule rule in rules) _endBefore(rule, local),
    ],
    dates: <LocalDateTime>[
      for (final date in dates)
        if (date.isBefore(local)) date,
    ],
    exceptions: <LocalDateTime>[
      for (final exception in exceptions)
        if (exception.isBefore(local)) exception,
    ],
  );

  /// The repetitions split at the one at [local]: those before it, and a
  /// new recurrence that starts there and repeats the rest, counts reduced
  /// by what the first part took.
  (RecurrenceSet, RecurrenceSet) splitAt(LocalDateTime local) {
    final RecurrenceSet head = truncatedBefore(local);
    final tail = RecurrenceSet(
      anchor.movedTo(local),
      rules: <RecurrenceRule>[
        for (final RecurrenceRule rule in rules) ..._remainderOf(rule, local),
      ],
      dates: <LocalDateTime>[
        for (final date in dates)
          if (!date.isBefore(local)) date,
      ],
      exceptions: <LocalDateTime>[
        for (final exception in exceptions)
          if (!exception.isBefore(local)) exception,
      ],
    );
    return (head, tail);
  }

  /// The repetitions moved so they start at [local]: extra dates,
  /// exceptions and ends move by the same distance, and a weekly rule on
  /// the old weekday, a monthly rule on the old day and a yearly rule in
  /// the old month follow to the new one.
  RecurrenceSet movedTo(LocalDateTime local) {
    final LocalDateTime old = anchor.local;
    final int days = old.date.daysUntil(local.date);
    final int nanos =
        local.time.toNanosecondOfDay() - old.time.toNanosecondOfDay();
    final int seconds = days * secondsPerDay + floorDiv(nanos, nanosPerSecond);
    final int rest = floorMod(nanos, nanosPerSecond);
    LocalDateTime move(LocalDateTime value) => _shift(value, seconds, rest);
    return RecurrenceSet(
      anchor.movedTo(local),
      rules: <RecurrenceRule>[
        for (final RecurrenceRule rule in rules)
          _follow(rule, old.date, local.date, move),
      ],
      dates: dates.map(move).toList(),
      exceptions: exceptions.map(move).toList(),
    );
  }

  /// What remains of [rule] from [local] on: the rule itself, with its
  /// count reduced by the repetitions before, or nothing when none remain.
  List<RecurrenceRule> _remainderOf(RecurrenceRule rule, LocalDateTime local) {
    final int? count = rule.count;
    if (count == null) {
      return <RecurrenceRule>[rule];
    }
    final int remaining = count - _countBefore(rule, local);
    if (remaining < 1) {
      return const <RecurrenceRule>[];
    }
    return <RecurrenceRule>[rule.copyWith(count: remaining)];
  }

  /// [rule] ended right before [local].
  RecurrenceRule _endBefore(RecurrenceRule rule, LocalDateTime local) {
    final int? count = rule.count;
    if (count != null) {
      final int before = _countBefore(rule, local);
      return rule.copyWith(count: before < 1 ? 1 : before);
    }
    final RecurrenceUntil until = switch (anchor) {
      DateAnchor() => RecurrenceUntilDate(local.date.plusDays(-1)),
      FloatingAnchor() => RecurrenceUntilLocal(_shift(local, -1, 0)),
      ZonedAnchor(:final TimeZone zone) => RecurrenceUntilInstant(
        zone.toInstant(local) - const Duration(seconds: 1),
      ),
    };
    final RecurrenceUntil? current = rule.until;
    if (current != null &&
        !current.admits(until.lastLocalIn(anchor.zone), anchor.zone)) {
      return rule;
    }
    return rule.copyWith(until: until);
  }

  /// How many repetitions [rule] and the anchor make before [local].
  int _countBefore(RecurrenceRule rule, LocalDateTime local) {
    final seen = <LocalDateTime>{
      if (anchor.local.isBefore(local)) anchor.local,
    };
    for (final LocalDateTime candidate in expandRule(
      rule,
      anchor.local,
      dateOnly: anchor is DateAnchor,
      zone: anchor.zone,
    )) {
      if (!candidate.isBefore(local)) {
        break;
      }
      seen.add(candidate);
    }
    return seen.length;
  }

  /// [rule] moved from [from] to [to]: its end by [move], and its pinned
  /// weekday, day of the month or month along with the start.
  static RecurrenceRule _follow(
    RecurrenceRule rule,
    LocalDate from,
    LocalDate to,
    LocalDateTime Function(LocalDateTime value) move,
  ) {
    final RecurrenceUntil? until = rule.until;
    final RecurrenceUntil? movedUntil = switch (until) {
      null => null,
      RecurrenceUntilDate(:final LocalDate date) => RecurrenceUntilDate(
        move(LocalDateTime(date, LocalTime.midnight)).date,
      ),
      RecurrenceUntilLocal(:final LocalDateTime local) => RecurrenceUntilLocal(
        move(local),
      ),
      RecurrenceUntilInstant(:final Instant instant) => RecurrenceUntilInstant(
        TimeZone.utc.toInstant(move(TimeZone.utc.toLocalDateTime(instant))),
      ),
    };
    final weekly = rule.frequency == RecurrenceFrequency.weekly;
    final monthly = rule.frequency == RecurrenceFrequency.monthly;
    final yearly = rule.frequency == RecurrenceFrequency.yearly;
    return rule.copyWith(
      until: movedUntil,
      byDay: weekly
          ? rule.byDay
                .map(
                  (day) => day.day == from.dayOfWeek
                      ? RecurrenceWeekday(to.dayOfWeek)
                      : day,
                )
                .toList()
          : null,
      byMonthDay: monthly
          ? rule.byMonthDay
                .map((day) => day == from.day ? to.day : day)
                .toList()
          : null,
      byMonth: yearly
          ? rule.byMonth
                .map(
                  (month) => month == from.monthNumber ? to.monthNumber : month,
                )
                .toList()
          : null,
    );
  }

  /// [local] moved by [seconds] and [nanos], on the local timeline.
  static LocalDateTime _shift(LocalDateTime local, int seconds, int nanos) {
    final int nanosOfSecond = local.nanosecond + nanos;
    final int total =
        local.localEpochSeconds +
        seconds +
        floorDiv(nanosOfSecond, nanosPerSecond);
    return LocalDateTime(
      LocalDate.fromEpochDays(floorDiv(total, secondsPerDay)),
      LocalTime.fromNanosecondOfDay(
        floorMod(total, secondsPerDay) * nanosPerSecond +
            floorMod(nanosOfSecond, nanosPerSecond),
      ),
    );
  }

  /// Whether [other] has the same anchor, rules, dates and exceptions.
  @override
  bool operator ==(Object other) =>
      other is RecurrenceSet &&
      other.anchor == anchor &&
      _sameList(other.rules, rules) &&
      _sameList(other.dates, dates) &&
      other.exceptions.length == exceptions.length &&
      other.exceptions.containsAll(exceptions);

  /// Whether [a] and [b] hold equal elements in the same order.
  static bool _sameList(List<Object> a, List<Object> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) {
        return false;
      }
    }
    return true;
  }

  /// A hash of the recurrence.
  @override
  int get hashCode => Object.hash(
    anchor,
    Object.hashAll(rules),
    Object.hashAll(dates),
    Object.hashAllUnordered(exceptions),
  );

  /// Describes the recurrence.
  @override
  String toString() =>
      'RecurrenceSet($anchor, rules: $rules, dates: $dates, '
      'exceptions: ${exceptions.toList()..sort()})';
}
