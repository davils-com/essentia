/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';
import 'package:essentia_time/essentia_time.dart';
import 'package:essentia_time/recurrence.dart';
import 'package:test/test.dart';

/// The codes of the violations [rule] reports.
List<String> _codes(String rule) {
  try {
    RecurrenceRule.parse(rule);
    return const <String>[];
  } on ValidationException catch (error) {
    return <String>[
      for (final Violation violation in error.report.violations)
        violation.code.value,
    ];
  }
}

/// Covers recurrence rules: reading, writing, checking and building.
void main() {
  group('reading and writing', () {
    test('writes its parts in a fixed order', () {
      final rule = RecurrenceRule.parse(
        'rrule:wkst=su;bysetpos=-1;bymonth=3;byweekno=1;byyearday=5;'
        'bymonthday=-1;byday=fr,mo;byhour=9;byminute=30;bysecond=15;'
        'interval=2;count=4;freq=yearly',
      );

      expect(
        rule.toString(),
        'FREQ=YEARLY;COUNT=4;INTERVAL=2;BYSECOND=15;BYMINUTE=30;BYHOUR=9;'
        'BYDAY=FR,MO;BYMONTHDAY=-1;BYYEARDAY=5;BYWEEKNO=1;BYMONTH=3;'
        'BYSETPOS=-1;WKST=SU',
      );
    });

    test('reads and writes ends of every kind', () {
      final RecurrenceUntil? date = RecurrenceRule.parse(
        'FREQ=DAILY;UNTIL=20261231',
      ).until;
      final RecurrenceUntil? local = RecurrenceRule.parse(
        'FREQ=DAILY;UNTIL=20261231T235959',
      ).until;
      final RecurrenceUntil? instant = RecurrenceRule.parse(
        'FREQ=DAILY;UNTIL=20261231T235959Z',
      ).until;

      expect(date, RecurrenceUntilDate(LocalDate(2026, 12, 31)));
      expect(date.toString(), '20261231');
      expect(
        local,
        RecurrenceUntilLocal(LocalDateTime.of(2026, 12, 31, 23, 59, 59)),
      );
      expect(local.toString(), '20261231T235959');
      expect(
        instant,
        RecurrenceUntilInstant(Instant.parse('2026-12-31T23:59:59Z')),
      );
      expect(instant.toString(), '20261231T235959Z');
      expect(
        date.hashCode,
        RecurrenceUntilDate(LocalDate(2026, 12, 31)).hashCode,
      );
      expect(local.hashCode, local?.hashCode);
      expect(instant.hashCode, instant?.hashCode);
      expect(() => RecurrenceUntil.parse('2026-12-31'), throwsFormatException);
      expect(() => RecurrenceUntil.parse('20261332'), throwsFormatException);
    });

    test('refuses text that is no rule', () {
      expect(() => RecurrenceRule.parse('COUNT=3'), throwsFormatException);
      expect(() => RecurrenceRule.parse('FREQ=OFTEN'), throwsFormatException);
      expect(
        () => RecurrenceRule.parse('FREQ=DAILY;COUNT'),
        throwsFormatException,
      );
      expect(
        () => RecurrenceRule.parse('FREQ=DAILY;COUNT=x'),
        throwsFormatException,
      );
      expect(
        () => RecurrenceRule.parse('FREQ=DAILY;BYDAY=XX'),
        throwsFormatException,
      );
      expect(
        RecurrenceRule.parse('FREQ=DAILY;;').frequency,
        RecurrenceFrequency.daily,
      );
    });

    test('reads weekdays with and without ordinals', () {
      expect(
        RecurrenceWeekday.parse('mo'),
        const RecurrenceWeekday(DayOfWeek.monday),
      );
      expect(
        RecurrenceWeekday.parse('+2TU'),
        const RecurrenceWeekday(DayOfWeek.tuesday, 2),
      );
      expect(RecurrenceWeekday.parse('-1SU').toString(), '-1SU');
      expect(
        const RecurrenceWeekday(DayOfWeek.friday, 3).hashCode,
        const RecurrenceWeekday(DayOfWeek.friday, 3).hashCode,
      );
      expect(RecurrenceWeekday.tokenOf(DayOfWeek.saturday), 'SA');
      expect(RecurrenceFrequency.ofToken('weekly'), RecurrenceFrequency.weekly);
      expect(RecurrenceFrequency.ofToken('never'), isNull);
      expect(RecurrenceFrequency.hourly.isTimeBased, isTrue);
      expect(RecurrenceFrequency.daily.isTimeBased, isFalse);
    });
  });

  group('checks', () {
    test('report every problem at once', () {
      expect(_codes('FREQ=DAILY;INTERVAL=0;COUNT=0'), <String>[
        'essentia.recurrence.interval',
        'essentia.recurrence.count',
      ]);
      expect(_codes('FREQ=DAILY;COUNT=2;UNTIL=20261231'), <String>[
        'essentia.recurrence.count-and-until',
      ]);
      expect(
        _codes('FREQ=DAILY;BYSECOND=60;BYMINUTE=60;BYHOUR=24;BYMONTH=13'),
        hasLength(4),
      );
      expect(
        _codes('FREQ=YEARLY;BYMONTHDAY=0;BYYEARDAY=367;BYWEEKNO=54;BYSETPOS=0'),
        hasLength(4),
      );
    });

    test('refuse parts that do not apply', () {
      expect(_codes('FREQ=MONTHLY;BYWEEKNO=3'), <String>[
        'essentia.recurrence.not-applicable',
      ]);
      expect(_codes('FREQ=WEEKLY;BYYEARDAY=3'), <String>[
        'essentia.recurrence.not-applicable',
      ]);
      expect(_codes('FREQ=WEEKLY;BYMONTHDAY=3'), <String>[
        'essentia.recurrence.not-applicable',
      ]);
      expect(_codes('FREQ=WEEKLY;BYDAY=1MO'), <String>[
        'essentia.recurrence.ordinal',
      ]);
      expect(_codes('FREQ=YEARLY;BYWEEKNO=1;BYDAY=1MO'), <String>[
        'essentia.recurrence.ordinal',
      ]);
      expect(_codes('FREQ=MONTHLY;BYDAY=60MO'), <String>[
        'essentia.recurrence.out-of-range',
      ]);
      expect(_codes('FREQ=MONTHLY;BYSETPOS=1'), <String>[
        'essentia.recurrence.set-position-alone',
      ]);
      expect(_codes('FREQ=MONTHLY;BYDAY=MO;BYSETPOS=1'), isEmpty);
    });
  });

  group('building', () {
    test('builds a rule in a block', () {
      final RecurrenceRule rule = recurrenceRule((it) {
        it
          ..frequency = RecurrenceFrequency.monthly
          ..interval = 2
          ..count = 5
          ..weekday(DayOfWeek.tuesday, 2)
          ..bySetPosition = <int>[1]
          ..byMonth = <int>[1, 3]
          ..byMonthDay = <int>[8, 9, 10, 11, 12, 13, 14]
          ..byHour = <int>[9]
          ..byMinute = <int>[30]
          ..bySecond = <int>[0]
          ..weekStart = DayOfWeek.sunday;
      });

      expect(
        rule.toString(),
        'FREQ=MONTHLY;COUNT=5;INTERVAL=2;BYSECOND=0;BYMINUTE=30;BYHOUR=9;'
        'BYDAY=2TU;BYMONTHDAY=8,9,10,11,12,13,14;BYMONTH=1,3;BYSETPOS=1;'
        'WKST=SU',
      );
    });

    test('reports every problem of the block', () {
      expect(
        () => recurrenceRule((it) {
          it
            ..interval = 0
            ..byYearDay = <int>[0]
            ..until = RecurrenceUntilDate(LocalDate(2026, 1, 1));
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        recurrenceRule((it) => it.byWeekNumber = <int>[]).frequency,
        RecurrenceFrequency.daily,
      );
    });

    test('copies with parts replaced and removed', () {
      final rule = RecurrenceRule.parse('FREQ=WEEKLY;COUNT=3;BYDAY=MO');

      expect(rule.copyWith(interval: 2).interval, 2);
      expect(rule.copyWith(clearCount: true).count, isNull);
      expect(rule.copyWith(clearCount: true).isInfinite, isTrue);
      expect(
        rule
            .copyWith(
              clearCount: true,
              until: RecurrenceUntilDate(LocalDate(2027, 1, 1)),
            )
            .until,
        RecurrenceUntilDate(LocalDate(2027, 1, 1)),
      );
      expect(
        rule
            .copyWith(
              clearCount: true,
              until: RecurrenceUntilDate(LocalDate(2027, 1, 1)),
            )
            .copyWith(clearUntil: true)
            .isInfinite,
        isTrue,
      );
      expect(rule, RecurrenceRule.parse('FREQ=WEEKLY;BYDAY=MO;COUNT=3'));
      expect(
        rule.hashCode,
        RecurrenceRule.parse('FREQ=WEEKLY;BYDAY=MO;COUNT=3').hashCode,
      );
    });
  });
}
