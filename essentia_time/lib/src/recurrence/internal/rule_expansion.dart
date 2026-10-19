/*
 * Copyright 2026 Davils
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:essentia_time/src/date/day_of_week.dart';
import 'package:essentia_time/src/date/local_date.dart';
import 'package:essentia_time/src/date/local_date_time.dart';
import 'package:essentia_time/src/date/local_time.dart';
import 'package:essentia_time/src/date/year_month.dart';
import 'package:essentia_time/src/internal/time_math.dart';
import 'package:essentia_time/src/recurrence/recurrence_frequency.dart';
import 'package:essentia_time/src/recurrence/recurrence_rule.dart';
import 'package:essentia_time/src/recurrence/recurrence_until.dart';
import 'package:essentia_time/src/recurrence/recurrence_weekday.dart';
import 'package:essentia_time/src/zone/time_zone.dart';
import 'package:meta/meta.dart';

/// How many days may pass without a single repetition before a rule is
/// taken to repeat no more: four hundred years, longer than any real rule
/// waits, so an impossible rule such as the 30th of February ends.
const int _daysWithoutRepetition = 400 * 366;

/// The local times [rule] repeats at from [start] on, in time order, the
/// way RFC 5545 expands it: [start] itself only when the rule produces it.
///
/// [dateOnly] repeats whole days. [zone] is the zone the local times are
/// read in, which an end at a moment needs. With [from] and no count, the
/// expansion skips ahead to the period of [from] and yields nothing
/// before it.
@internal
Iterable<LocalDateTime> expandRule(
  RecurrenceRule rule,
  LocalDateTime start, {
  required bool dateOnly,
  TimeZone? zone,
  LocalDateTime? from,
}) sync* {
  final int? count = rule.count;
  final RecurrenceUntil? until = rule.until;
  final LocalDateTime? last = until?.lastLocalIn(zone);
  int step = count == null && from != null && from.isAfter(start)
      ? _firstStep(rule, start, from)
      : 0;
  var emitted = 0;
  var first = true;
  LocalDate productive = start.date;
  while (true) {
    final LocalDate periodStart = _periodStart(rule, start, step);
    if (last != null && periodStart.isAfter(last.date.plusDays(7))) {
      return;
    }
    if (productive.daysUntil(periodStart) > _daysWithoutRepetition) {
      return;
    }
    final (List<LocalDateTime> candidates, int next) = _period(
      rule,
      start,
      step,
      dateOnly: dateOnly,
    );
    step = next;
    if (candidates.isNotEmpty) {
      productive = periodStart;
    }
    for (final candidate in candidates) {
      if (candidate.isBefore(start)) {
        continue;
      }
      if (until != null && !until.admits(candidate, zone)) {
        return;
      }
      if (first) {
        first = false;
        if (candidate != start) {
          emitted = 1;
        }
      }
      if (count != null && emitted >= count) {
        return;
      }
      emitted += 1;
      if (from != null && candidate.isBefore(from)) {
        continue;
      }
      yield candidate;
    }
  }
}

/// The first step to expand when the expansion may begin at [from]: one
/// period before the period of [from], so nothing near it is missed.
int _firstStep(RecurrenceRule rule, LocalDateTime start, LocalDateTime from) {
  final int periods = switch (rule.frequency) {
    RecurrenceFrequency.yearly => from.year - start.year,
    RecurrenceFrequency.monthly => start.date.yearMonth.monthsUntil(
      from.date.yearMonth,
    ),
    RecurrenceFrequency.weekly =>
      start.date
              .startOfWeek(rule.weekStart)
              .daysUntil(from.date.startOfWeek(rule.weekStart)) ~/
          7,
    RecurrenceFrequency.daily => start.date.daysUntil(from.date),
    RecurrenceFrequency.hourly ||
    RecurrenceFrequency.minutely ||
    RecurrenceFrequency.secondly =>
      (from.localEpochSeconds - _base(rule, start)) ~/ _unitSeconds(rule),
  };
  final int step = periods ~/ rule.interval - 1;
  return step < 0 ? 0 : step;
}

/// The first day the period of [step] can repeat on.
LocalDate _periodStart(RecurrenceRule rule, LocalDateTime start, int step) {
  final int periods = step * rule.interval;
  return switch (rule.frequency) {
    RecurrenceFrequency.yearly => LocalDate(
      start.year + periods,
      1,
      1,
    ).plusDays(-7),
    RecurrenceFrequency.monthly =>
      start.date.yearMonth.plusMonths(periods).firstDay,
    RecurrenceFrequency.weekly =>
      start.date.startOfWeek(rule.weekStart).plusDays(7 * periods),
    RecurrenceFrequency.daily => start.date.plusDays(periods),
    RecurrenceFrequency.hourly ||
    RecurrenceFrequency.minutely ||
    RecurrenceFrequency.secondly => LocalDate.fromEpochDays(
      floorDiv(
        _base(rule, start) + periods * _unitSeconds(rule),
        secondsPerDay,
      ),
    ),
  };
}

/// The repetitions of the period of [step], in time order and picked by
/// `BYSETPOS`, and the step to expand next.
(List<LocalDateTime>, int) _period(
  RecurrenceRule rule,
  LocalDateTime start,
  int step, {
  required bool dateOnly,
}) {
  if (rule.frequency.isTimeBased) {
    return _timePeriod(rule, start, step);
  }
  final List<LocalDate> dates = _dates(rule, start.date, step);
  final List<LocalTime> times = dateOnly
      ? const <LocalTime>[LocalTime.midnight]
      : _times(rule, start.time);
  final List<LocalDateTime> candidates = <LocalDateTime>{
    for (final date in dates)
      for (final time in times) LocalDateTime(date, time),
  }.toList()..sort();
  return (_select(rule, candidates), step + 1);
}

/// The repetitions of the period of [step] of a rule that repeats within
/// a day, and the step to expand next, which skips days, hours and
/// minutes the rule leaves out.
(List<LocalDateTime>, int) _timePeriod(
  RecurrenceRule rule,
  LocalDateTime start,
  int step,
) {
  final int base = _base(rule, start);
  final int stride = _unitSeconds(rule) * rule.interval;
  final int seconds = base + step * stride;
  final date = LocalDate.fromEpochDays(floorDiv(seconds, secondsPerDay));
  final time = LocalTime.fromSecondOfDay(floorMod(seconds, secondsPerDay));
  int nextAt(int target) {
    final int distance = target - base;
    final int next = (distance + stride - 1) ~/ stride;
    return next > step ? next : step + 1;
  }

  if (!_dayMatches(rule, date)) {
    return (
      const <LocalDateTime>[],
      nextAt((date.epochDays + 1) * secondsPerDay),
    );
  }
  if (rule.byHour.isNotEmpty && !rule.byHour.contains(time.hour)) {
    return (
      const <LocalDateTime>[],
      nextAt(seconds - time.minute * 60 - time.second + 3600),
    );
  }
  final RecurrenceFrequency frequency = rule.frequency;
  final limitsMinutes = frequency != RecurrenceFrequency.hourly;
  if (limitsMinutes &&
      rule.byMinute.isNotEmpty &&
      !rule.byMinute.contains(time.minute)) {
    return (const <LocalDateTime>[], nextAt(seconds - time.second + 60));
  }
  if (frequency == RecurrenceFrequency.secondly &&
      rule.bySecond.isNotEmpty &&
      !rule.bySecond.contains(time.second)) {
    return (const <LocalDateTime>[], step + 1);
  }
  final List<int> minutes = limitsMinutes
      ? <int>[time.minute]
      : (rule.byMinute.isEmpty ? <int>[start.minute] : rule.byMinute);
  final List<int> secondsOfMinute = frequency == RecurrenceFrequency.secondly
      ? <int>[time.second]
      : (rule.bySecond.isEmpty ? <int>[start.second] : rule.bySecond);
  final candidates = <LocalDateTime>[
    for (final minute in minutes)
      for (final second in secondsOfMinute)
        LocalDateTime(
          date,
          LocalTime(time.hour, minute, second, start.nanosecond),
        ),
  ];
  return (_select(rule, candidates), step + 1);
}

/// The local seconds since the epoch of the start of the unit [start]
/// lies in, for a rule that repeats within a day.
int _base(RecurrenceRule rule, LocalDateTime start) {
  final int seconds = start.localEpochSeconds;
  return switch (rule.frequency) {
    RecurrenceFrequency.hourly => seconds - start.minute * 60 - start.second,
    RecurrenceFrequency.minutely => seconds - start.second,
    RecurrenceFrequency.secondly ||
    RecurrenceFrequency.daily ||
    RecurrenceFrequency.weekly ||
    RecurrenceFrequency.monthly ||
    RecurrenceFrequency.yearly => seconds,
  };
}

/// The seconds of one unit of a rule that repeats within a day.
int _unitSeconds(RecurrenceRule rule) => switch (rule.frequency) {
  RecurrenceFrequency.hourly => 3600,
  RecurrenceFrequency.minutely => 60,
  RecurrenceFrequency.secondly ||
  RecurrenceFrequency.daily ||
  RecurrenceFrequency.weekly ||
  RecurrenceFrequency.monthly ||
  RecurrenceFrequency.yearly => 1,
};

/// [candidates] picked by the `BYSETPOS` of [rule], or all of them.
List<LocalDateTime> _select(
  RecurrenceRule rule,
  List<LocalDateTime> candidates,
) {
  if (rule.bySetPosition.isEmpty || candidates.isEmpty) {
    return candidates;
  }
  return <LocalDateTime>{
    for (final position in rule.bySetPosition)
      if (position.abs() <= candidates.length)
        candidates[position > 0 ? position - 1 : candidates.length + position],
  }.toList()..sort();
}

/// The times of day a rule that repeats daily or less often repeats at.
List<LocalTime> _times(RecurrenceRule rule, LocalTime time) => <LocalTime>[
  for (final hour in rule.byHour.isEmpty ? <int>[time.hour] : rule.byHour)
    for (final minute
        in rule.byMinute.isEmpty ? <int>[time.minute] : rule.byMinute)
      for (final second
          in rule.bySecond.isEmpty ? <int>[time.second] : rule.bySecond)
        LocalTime(hour, minute, second, time.nanosecond),
];

/// The days the period of [step] repeats on, for a rule that repeats
/// daily or less often.
List<LocalDate> _dates(RecurrenceRule rule, LocalDate start, int step) {
  final int periods = step * rule.interval;
  return switch (rule.frequency) {
    RecurrenceFrequency.yearly => _yearDates(rule, start, start.year + periods),
    RecurrenceFrequency.monthly => _monthDates(
      rule,
      start,
      start.yearMonth.plusMonths(periods),
    ),
    RecurrenceFrequency.weekly => _weekDates(
      rule,
      start,
      start.startOfWeek(rule.weekStart).plusDays(7 * periods),
    ),
    RecurrenceFrequency.daily => <LocalDate>[
      if (_dayMatches(rule, start.plusDays(periods))) start.plusDays(periods),
    ],
    RecurrenceFrequency.hourly ||
    RecurrenceFrequency.minutely ||
    RecurrenceFrequency.secondly => const <LocalDate>[],
  };
}

/// The days of [year] a yearly rule repeats on.
List<LocalDate> _yearDates(RecurrenceRule rule, LocalDate start, int year) {
  final first = LocalDate(year, 1, 1);
  final last = LocalDate(year, 12, 31);
  final months = <YearMonth>[
    for (final int month
        in rule.byMonth.isEmpty
            ? <int>[for (var month = 1; month <= 12; month += 1) month]
            : rule.byMonth)
      YearMonth(year, month),
  ];
  if (rule.byWeekNumber.isNotEmpty) {
    final LocalDate week1 = _firstWeek(year, rule.weekStart);
    final int weeks =
        week1.daysUntil(_firstWeek(year + 1, rule.weekStart)) ~/ 7;
    final weekdays = rule.byDay.isEmpty
        ? <DayOfWeek>[start.dayOfWeek]
        : <DayOfWeek>[for (final day in rule.byDay) day.day];
    return <LocalDate>[
          for (final number in rule.byWeekNumber)
            if (number.abs() <= weeks)
              for (final weekday in weekdays)
                week1.plusDays(
                  7 * ((number > 0 ? number : weeks + number + 1) - 1) +
                      rule.weekStart.daysUntil(weekday),
                ),
        ]
        .where(
          (date) =>
              (rule.byMonth.isEmpty ||
                  rule.byMonth.contains(date.monthNumber)) &&
              _monthDayMatches(rule, date),
        )
        .toList();
  }
  if (rule.byYearDay.isNotEmpty) {
    return <LocalDate>[
          for (final day in rule.byYearDay)
            if (day > 0 && day <= first.lengthOfYear) first.plusDays(day - 1),
          for (final day in rule.byYearDay)
            if (day < 0 && -day <= first.lengthOfYear) last.plusDays(day + 1),
        ]
        .where(
          (date) =>
              (rule.byMonth.isEmpty ||
                  rule.byMonth.contains(date.monthNumber)) &&
              _monthDayMatches(rule, date) &&
              _weekdayMatches(
                rule,
                date,
                rule.byMonth.isEmpty ? first : date.firstDayOfMonth,
                rule.byMonth.isEmpty ? last : date.lastDayOfMonth,
              ),
        )
        .toList();
  }
  if (rule.byMonthDay.isNotEmpty) {
    return <LocalDate>[
      for (final month in months)
        for (final date in _monthDays(rule, month))
          if (_weekdayMatches(
            rule,
            date,
            rule.byMonth.isEmpty ? first : month.firstDay,
            rule.byMonth.isEmpty ? last : month.lastDay,
          ))
            date,
    ];
  }
  if (rule.byDay.isNotEmpty) {
    if (rule.byMonth.isEmpty) {
      return _expandWeekdays(rule.byDay, first, last);
    }
    return <LocalDate>[
      for (final month in months)
        ..._expandWeekdays(rule.byDay, month.firstDay, month.lastDay),
    ];
  }
  if (rule.byMonth.isNotEmpty) {
    return <LocalDate>[
      for (final month in months)
        if (start.day <= month.numberOfDays) month.onDay(start.day),
    ];
  }
  final month = YearMonth(year, start.monthNumber);
  return <LocalDate>[
    if (start.day <= month.numberOfDays) month.onDay(start.day),
  ];
}

/// The days of [month] a monthly rule repeats on.
List<LocalDate> _monthDates(
  RecurrenceRule rule,
  LocalDate start,
  YearMonth month,
) {
  if (rule.byMonth.isNotEmpty && !rule.byMonth.contains(month.monthNumber)) {
    return const <LocalDate>[];
  }
  if (rule.byMonthDay.isNotEmpty) {
    return <LocalDate>[
      for (final date in _monthDays(rule, month))
        if (_weekdayMatches(rule, date, month.firstDay, month.lastDay)) date,
    ];
  }
  if (rule.byDay.isNotEmpty) {
    return _expandWeekdays(rule.byDay, month.firstDay, month.lastDay);
  }
  return <LocalDate>[
    if (start.day <= month.numberOfDays) month.onDay(start.day),
  ];
}

/// The days of the week starting on [weekStart] a weekly rule repeats on.
List<LocalDate> _weekDates(
  RecurrenceRule rule,
  LocalDate start,
  LocalDate weekStart,
) {
  final weekdays = rule.byDay.isEmpty
      ? <DayOfWeek>[start.dayOfWeek]
      : <DayOfWeek>[for (final day in rule.byDay) day.day];
  return <LocalDate>[
        for (final weekday in weekdays)
          weekStart.plusDays(rule.weekStart.daysUntil(weekday)),
      ]
      .where(
        (date) =>
            rule.byMonth.isEmpty || rule.byMonth.contains(date.monthNumber),
      )
      .toList();
}

/// The days of `BYMONTHDAY` that [month] has.
List<LocalDate> _monthDays(RecurrenceRule rule, YearMonth month) => <LocalDate>[
  for (final day in rule.byMonthDay)
    if (day.abs() <= month.numberOfDays)
      month.onDay(day > 0 ? day : month.numberOfDays + day + 1),
];

/// Whether [date] passes the limits of a rule that repeats daily or more
/// often: its months, days of the year and month, and weekdays.
bool _dayMatches(RecurrenceRule rule, LocalDate date) =>
    (rule.byMonth.isEmpty || rule.byMonth.contains(date.monthNumber)) &&
    _monthDayMatches(rule, date) &&
    (rule.byYearDay.isEmpty || _yearDayMatches(rule, date)) &&
    (rule.byDay.isEmpty || rule.byDay.any((day) => day.day == date.dayOfWeek));

/// Whether [date] is one of the `BYMONTHDAY` days, or there are none.
bool _monthDayMatches(RecurrenceRule rule, LocalDate date) =>
    rule.byMonthDay.isEmpty ||
    rule.byMonthDay.any(
      (day) => day == date.day || day == date.day - date.lengthOfMonth - 1,
    );

/// Whether [date] is one of the `BYYEARDAY` days.
bool _yearDayMatches(RecurrenceRule rule, LocalDate date) => rule.byYearDay.any(
  (day) =>
      day == date.dayOfYear || day == date.dayOfYear - date.lengthOfYear - 1,
);

/// Whether [date] is one of the `BYDAY` weekdays, the ordinals counted
/// from [first] to [last], or there are none.
bool _weekdayMatches(
  RecurrenceRule rule,
  LocalDate date,
  LocalDate first,
  LocalDate last,
) =>
    rule.byDay.isEmpty ||
    _expandWeekdays(rule.byDay, first, last).contains(date);

/// The days from [first] to [last] that are one of [days], each with its
/// ordinal counted from [first], or from [last] when negative.
List<LocalDate> _expandWeekdays(
  List<RecurrenceWeekday> days,
  LocalDate first,
  LocalDate last,
) {
  final result = <LocalDate>[];
  for (final day in days) {
    final LocalDate earliest = first.plusDays(
      first.dayOfWeek.daysUntil(day.day),
    );
    final int count = earliest.isAfter(last)
        ? 0
        : earliest.daysUntil(last) ~/ 7 + 1;
    final int? ordinal = day.ordinal;
    if (ordinal == null) {
      for (var index = 0; index < count; index += 1) {
        result.add(earliest.plusDays(7 * index));
      }
      continue;
    }
    if (ordinal.abs() <= count) {
      result.add(
        earliest.plusDays(7 * (ordinal > 0 ? ordinal - 1 : count + ordinal)),
      );
    }
  }
  return result;
}

/// The first day of the first week of [year] for weeks starting on
/// [weekStart]: the week that holds at least four days of the year.
LocalDate _firstWeek(int year, DayOfWeek weekStart) {
  final first = LocalDate(year, 1, 1);
  final LocalDate start = first.startOfWeek(weekStart);
  return 7 - start.daysUntil(first) >= 4 ? start : start.plusDays(7);
}
