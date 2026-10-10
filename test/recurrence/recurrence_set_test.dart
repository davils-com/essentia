/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';
import 'package:essentia/icalendar.dart';
import 'package:test/test.dart';

/// The zone most examples are set in.
final TimeZone _berlin = TimeZone.of('Europe/Berlin');

/// A set of [rule] from [start] in Berlin.
RecurrenceSet _zoned(String start, String rule) => RecurrenceSet(
  ZonedAnchor(LocalDateTime.parse(start), _berlin),
  rules: <RecurrenceRule>[RecurrenceRule.parse(rule)],
);

/// The local times of [occurrences] as text.
List<String> _locals(Iterable<RecurrenceOccurrence> occurrences) =>
    occurrences.map((it) => it.local.toString()).toList();

/// Covers recurrence sets: anchors of every kind, extra dates and
/// exceptions, windows, the shifts of the clocks and series edits.
void main() {
  group('anchors', () {
    test('repeat whole days without a zone', () {
      final set = RecurrenceSet(
        DateAnchor(LocalDate(2026, 12, 24)),
        rules: <RecurrenceRule>[RecurrenceRule.parse('FREQ=YEARLY;COUNT=3')],
      );

      expect(set.occurrences().map((it) => it.date).toList(), <LocalDate>[
        LocalDate(2026, 12, 24),
        LocalDate(2027, 12, 24),
        LocalDate(2028, 12, 24),
      ]);
      expect(set.occurrences().first.instant, isNull);
      expect(
        set.occurrences().first.instantIn(_berlin),
        Instant.parse('2026-12-23T23:00:00Z'),
      );
      expect(
        () => RecurrenceSet(
          DateAnchor(LocalDate(2026, 1, 1)),
          rules: <RecurrenceRule>[RecurrenceRule.parse('FREQ=HOURLY')],
        ),
        throwsArgumentError,
      );
      expect(
        () => RecurrenceSet(
          DateAnchor(LocalDate(2026, 1, 1)),
          rules: <RecurrenceRule>[RecurrenceRule.parse('FREQ=DAILY;BYHOUR=9')],
        ),
        throwsArgumentError,
      );
    });

    test('float with the clocks without a zone', () {
      final set = RecurrenceSet(
        FloatingAnchor(LocalDateTime.of(2026, 3, 28, 2, 30)),
        rules: <RecurrenceRule>[RecurrenceRule.parse('FREQ=DAILY;COUNT=3')],
      );

      expect(_locals(set.occurrences()), <String>[
        '2026-03-28T02:30',
        '2026-03-29T02:30',
        '2026-03-30T02:30',
      ]);
      expect(set.occurrences().every((it) => it.instant == null), isTrue);
    });

    test('keep the local time across the shifts of the clocks', () {
      final RecurrenceSet set = _zoned(
        '2026-03-28T02:30',
        'FREQ=DAILY;COUNT=3',
      );
      final List<RecurrenceOccurrence> list = set.occurrences().toList();

      expect(_locals(list), <String>[
        '2026-03-28T02:30',
        '2026-03-29T02:30',
        '2026-03-30T02:30',
      ]);
      expect(list[0].instant, Instant.parse('2026-03-28T01:30:00Z'));
      expect(list[1].instant, Instant.parse('2026-03-29T01:30:00Z'));
      expect(list[2].instant, Instant.parse('2026-03-30T00:30:00Z'));
    });

    test('compare and move', () {
      final anchor = ZonedAnchor(LocalDateTime.of(2026, 1, 1, 9, 0), _berlin);

      expect(anchor, ZonedAnchor(LocalDateTime.of(2026, 1, 1, 9, 0), _berlin));
      expect(
        anchor.hashCode,
        ZonedAnchor(LocalDateTime.of(2026, 1, 1, 9, 0), _berlin).hashCode,
      );
      expect(
        ZonedAnchor.at(Instant.parse('2026-01-01T08:00:00Z'), _berlin),
        anchor,
      );
      expect(anchor.toString(), 'ZonedAnchor(2026-01-01T09:00, Europe/Berlin)');
      expect(anchor.movedTo(LocalDateTime.of(2026, 1, 2, 9, 0)).local.day, 2);
      final floating = FloatingAnchor(LocalDateTime.of(2026, 1, 1, 9, 0));
      expect(floating, FloatingAnchor(LocalDateTime.of(2026, 1, 1, 9, 0)));
      expect(
        floating.hashCode,
        FloatingAnchor(LocalDateTime.of(2026, 1, 1, 9, 0)).hashCode,
      );
      expect(floating.toString(), 'FloatingAnchor(2026-01-01T09:00)');
      expect(floating.movedTo(LocalDateTime.of(2026, 1, 2, 9, 0)).local.day, 2);
      expect(floating.zone, isNull);
      final date = DateAnchor(LocalDate(2026, 1, 1));
      expect(date, DateAnchor(LocalDate(2026, 1, 1)));
      expect(date.hashCode, LocalDate(2026, 1, 1).hashCode);
      expect(date.toString(), 'DateAnchor(2026-01-01)');
      expect(
        date.movedTo(LocalDateTime.of(2026, 2, 3, 9, 0)).date,
        LocalDate(2026, 2, 3),
      );
      expect(date.zone, isNull);
    });
  });

  group('sets', () {
    test('merge extra dates, drop exceptions and repeats', () {
      final set = RecurrenceSet(
        ZonedAnchor(LocalDateTime.of(2026, 10, 5, 9, 0), _berlin),
        rules: <RecurrenceRule>[
          RecurrenceRule.parse('FREQ=WEEKLY;COUNT=3'),
          RecurrenceRule.parse('FREQ=WEEKLY;INTERVAL=2;COUNT=2'),
        ],
        dates: <LocalDateTime>[
          LocalDateTime.of(2026, 10, 8, 14, 0),
          LocalDateTime.of(2026, 10, 8, 14, 0),
        ],
        exceptions: <LocalDateTime>[LocalDateTime.of(2026, 10, 12, 9, 0)],
      );

      expect(_locals(set.occurrences()), <String>[
        '2026-10-05T09:00',
        '2026-10-08T14:00',
        '2026-10-19T09:00',
      ]);
      expect(set.isInfinite, isFalse);
      expect(set.isSingle, isFalse);
      expect(RecurrenceSet(set.anchor).isSingle, isTrue);
      expect(_locals(RecurrenceSet(set.anchor).occurrences()), <String>[
        '2026-10-05T09:00',
      ]);
    });

    test('count the anchor when the rule would not produce it', () {
      final RecurrenceSet set = _zoned(
        '2026-10-06T09:00',
        'FREQ=WEEKLY;BYDAY=MO;COUNT=3',
      );

      expect(_locals(set.occurrences()), <String>[
        '2026-10-06T09:00',
        '2026-10-12T09:00',
        '2026-10-19T09:00',
      ]);
    });

    test('end an impossible rule instead of searching forever', () {
      final RecurrenceSet set = _zoned(
        '2026-01-01T09:00',
        'FREQ=YEARLY;BYMONTH=2;BYMONTHDAY=30',
      );

      expect(_locals(set.occurrences()), <String>['2026-01-01T09:00']);
      final RecurrenceSet daily = _zoned(
        '2026-01-01T09:00',
        'FREQ=DAILY;BYMONTH=2;BYMONTHDAY=31',
      );
      expect(daily.occurrences().length, 1);
    });

    test('skip days, hours and minutes a fine rule leaves out', () {
      final RecurrenceSet set = _zoned(
        '2026-01-01T00:00',
        'FREQ=SECONDLY;BYMONTH=3;BYDAY=MO;BYHOUR=10;BYMINUTE=15;BYSECOND=30',
      );

      expect(_locals(set.occurrences().skip(1).take(2)), <String>[
        '2026-03-02T10:15:30',
        '2026-03-09T10:15:30',
      ]);
      expect(
        _locals(
          _zoned(
            '2026-01-01T09:00',
            'FREQ=MINUTELY;BYSECOND=5,10;COUNT=3',
          ).occurrences(),
        ),
        <String>[
          '2026-01-01T09:00',
          '2026-01-01T09:00:05',
          '2026-01-01T09:00:10',
        ],
      );
      expect(
        _locals(
          _zoned(
            '2026-01-01T09:00',
            'FREQ=SECONDLY;INTERVAL=30;COUNT=3',
          ).occurrences(),
        ),
        <String>['2026-01-01T09:00', '2026-01-01T09:00:30', '2026-01-01T09:01'],
      );
      expect(
        _locals(
          _zoned(
            '2026-01-01T09:00:10',
            'FREQ=SECONDLY;BYSECOND=12;COUNT=2',
          ).occurrences(),
        ),
        <String>['2026-01-01T09:00:10', '2026-01-01T09:00:12'],
      );
    });

    test('expand week numbers and days of the year of every kind', () {
      expect(
        _locals(
          _zoned(
            '2026-01-01T09:00',
            'FREQ=YEARLY;BYWEEKNO=-1;COUNT=3',
          ).occurrences(),
        ),
        <String>['2026-01-01T09:00', '2026-12-31T09:00', '2027-12-30T09:00'],
      );
      expect(
        _locals(
          _zoned(
            '2026-01-01T09:00',
            'FREQ=YEARLY;BYYEARDAY=-1;COUNT=2',
          ).occurrences(),
        ),
        <String>['2026-01-01T09:00', '2026-12-31T09:00'],
      );
      expect(
        _locals(
          _zoned(
            '2026-01-01T09:00',
            'FREQ=YEARLY;BYYEARDAY=60;BYMONTH=3;COUNT=2',
          ).occurrences(),
        ),
        <String>['2026-01-01T09:00', '2026-03-01T09:00'],
      );
      expect(
        _locals(
          _zoned(
            '2026-01-05T09:00',
            'FREQ=YEARLY;BYMONTHDAY=5;BYDAY=MO;COUNT=2',
          ).occurrences(),
        ),
        <String>['2026-01-05T09:00', '2026-10-05T09:00'],
      );
      expect(
        _locals(
          _zoned(
            '2026-01-31T09:00',
            'FREQ=YEARLY;BYMONTH=2,3;COUNT=2',
          ).occurrences(),
        ),
        <String>['2026-01-31T09:00', '2026-03-31T09:00'],
      );
      expect(
        _locals(
          _zoned('2024-02-29T09:00', 'FREQ=YEARLY;COUNT=2').occurrences(),
        ),
        <String>['2024-02-29T09:00', '2028-02-29T09:00'],
      );
      expect(
        _locals(
          _zoned('2026-01-31T09:00', 'FREQ=MONTHLY;COUNT=3').occurrences(),
        ),
        <String>['2026-01-31T09:00', '2026-03-31T09:00', '2026-05-31T09:00'],
      );
      expect(
        _locals(
          _zoned(
            '2026-01-01T09:00',
            'FREQ=WEEKLY;BYMONTH=2;COUNT=2',
          ).occurrences(),
        ),
        <String>['2026-01-01T09:00', '2026-02-05T09:00'],
      );
    });
  });

  group('windows', () {
    final sets = <RecurrenceSet>[
      _zoned('2026-01-01T09:00', 'FREQ=DAILY'),
      _zoned('2026-01-01T09:00', 'FREQ=WEEKLY;INTERVAL=3;BYDAY=MO,FR'),
      _zoned('2026-01-31T09:00', 'FREQ=MONTHLY;BYMONTHDAY=-1,15'),
      _zoned('2026-01-01T09:00', 'FREQ=YEARLY;BYWEEKNO=1,52;BYDAY=TH'),
      _zoned('2026-01-01T09:00', 'FREQ=HOURLY;INTERVAL=7;BYHOUR=1,8,15'),
      _zoned('2026-01-01T09:00', 'FREQ=MINUTELY;INTERVAL=97'),
      _zoned(
        '2026-01-01T09:00',
        'FREQ=MONTHLY;BYDAY=MO,TU,WE,TH,FR;BYSETPOS=-1',
      ),
    ];

    test('skip ahead to exactly what a full expansion would show', () {
      final from = LocalDateTime.of(2029, 6, 15, 10, 0);
      final until = LocalDateTime.of(2029, 7, 20, 0, 0);
      for (final set in sets) {
        final List<String> slow = _locals(
          set
              .occurrences()
              .skipWhile((it) => it.local.isBefore(from))
              .takeWhile((it) => it.local.isBefore(until)),
        );

        expect(
          _locals(set.occurrencesBetween(from, until)),
          slow,
          reason: '${set.rules}',
        );
      }
    });

    test('include what started earlier and still lasts', () {
      final RecurrenceSet set = _zoned('2026-10-05T22:00', 'FREQ=DAILY');

      expect(
        _locals(
          set.occurrencesBetween(
            LocalDateTime.of(2026, 10, 7, 0, 0),
            LocalDateTime.of(2026, 10, 8, 0, 0),
            duration: const Duration(hours: 3),
          ),
        ),
        <String>['2026-10-06T22:00', '2026-10-07T22:00'],
      );
      expect(
        () => _zoned('2026-01-01T00:00', 'FREQ=SECONDLY').occurrencesBetween(
          LocalDateTime.of(2026, 1, 1, 0, 0),
          LocalDateTime.of(2026, 1, 2, 0, 0),
          limit: 10,
        ),
        throwsStateError,
      );
    });

    test('overlap moments, floating ones read in a zone', () {
      final RecurrenceSet zoned = _zoned('2026-10-05T09:00', 'FREQ=DAILY');
      final List<RecurrenceOccurrence> list = zoned.occurrencesOverlapping(
        Instant.parse('2026-10-07T06:00:00Z'),
        Instant.parse('2026-10-08T07:00:00Z'),
        duration: const Duration(hours: 1),
      );

      expect(_locals(list), <String>['2026-10-07T09:00']);
      final floating = RecurrenceSet(
        FloatingAnchor(LocalDateTime.of(2026, 10, 5, 9, 0)),
        rules: <RecurrenceRule>[RecurrenceRule.parse('FREQ=DAILY')],
      );
      expect(
        _locals(
          floating.occurrencesOverlapping(
            Instant.parse('2026-10-07T07:00:00Z'),
            Instant.parse('2026-10-07T08:00:00Z'),
            floatingZone: _berlin,
          ),
        ),
        <String>['2026-10-07T09:00'],
      );
    });

    test('find the neighbours of a moment', () {
      final RecurrenceSet set = _zoned(
        '2026-01-01T09:00',
        'FREQ=MONTHLY;BYMONTHDAY=1',
      );

      expect(
        set.firstAfter(LocalDateTime.of(2026, 3, 1, 9, 0))?.local,
        LocalDateTime.of(2026, 4, 1, 9, 0),
      );
      expect(
        set.lastBefore(LocalDateTime.of(2026, 3, 1, 9, 0))?.local,
        LocalDateTime.of(2026, 2, 1, 9, 0),
      );
      expect(
        set.lastBefore(LocalDateTime.of(2030, 3, 1, 9, 0))?.local,
        LocalDateTime.of(2030, 2, 1, 9, 0),
      );
      expect(set.lastBefore(LocalDateTime.of(2026, 1, 1, 9, 0)), isNull);
      expect(set.contains(LocalDateTime.of(2027, 5, 1, 9, 0)), isTrue);
      expect(set.contains(LocalDateTime.of(2027, 5, 2, 9, 0)), isFalse);
      final RecurrenceSet ended = _zoned(
        '2026-01-01T09:00',
        'FREQ=DAILY;COUNT=2',
      );
      expect(ended.firstAfter(LocalDateTime.of(2026, 1, 2, 9, 0)), isNull);
      expect(ended.contains(LocalDateTime.of(2027, 1, 1, 9, 0)), isFalse);
    });
  });

  group('series edits', () {
    test('cut off at an occurrence by end and by count', () {
      final RecurrenceSet byEnd = _zoned('2026-10-05T09:00', 'FREQ=DAILY');
      final RecurrenceSet head = byEnd.truncatedBefore(
        LocalDateTime.of(2026, 10, 8, 9, 0),
      );

      expect(_locals(head.occurrences()), <String>[
        '2026-10-05T09:00',
        '2026-10-06T09:00',
        '2026-10-07T09:00',
      ]);
      expect(
        head.rules.single.until,
        RecurrenceUntilInstant(Instant.parse('2026-10-08T06:59:59Z')),
      );
      final RecurrenceSet byCount = _zoned(
        '2026-10-05T09:00',
        'FREQ=DAILY;COUNT=10',
      );
      expect(
        byCount
            .truncatedBefore(LocalDateTime.of(2026, 10, 8, 9, 0))
            .rules
            .single
            .count,
        3,
      );
      final RecurrenceSet early = _zoned(
        '2026-10-05T09:00',
        'FREQ=DAILY;UNTIL=20261006T235959Z',
      );
      expect(
        early.truncatedBefore(LocalDateTime.of(2026, 10, 9, 9, 0)).rules.single,
        early.rules.single,
      );
    });

    test('cut off whole days and floating times', () {
      final days = RecurrenceSet(
        DateAnchor(LocalDate(2026, 10, 5)),
        rules: <RecurrenceRule>[RecurrenceRule.parse('FREQ=DAILY')],
        dates: <LocalDateTime>[LocalDateTime.of(2026, 12, 24, 0, 0)],
        exceptions: <LocalDateTime>[
          LocalDateTime.of(2026, 10, 6, 0, 0),
          LocalDateTime.of(2026, 10, 20, 0, 0),
        ],
      );
      final RecurrenceSet head = days.truncatedBefore(
        LocalDateTime.of(2026, 10, 8, 0, 0),
      );

      expect(
        head.rules.single.until,
        RecurrenceUntilDate(LocalDate(2026, 10, 7)),
      );
      expect(head.dates, isEmpty);
      expect(head.exceptions, <LocalDateTime>{
        LocalDateTime.of(2026, 10, 6, 0, 0),
      });
      final floating = RecurrenceSet(
        FloatingAnchor(LocalDateTime.of(2026, 10, 5, 9, 0)),
        rules: <RecurrenceRule>[RecurrenceRule.parse('FREQ=DAILY')],
      );
      expect(
        floating
            .truncatedBefore(LocalDateTime.of(2026, 10, 8, 9, 0))
            .rules
            .single
            .until,
        RecurrenceUntilLocal(LocalDateTime.of(2026, 10, 8, 8, 59, 59)),
      );
    });

    test('split into the part before and a new series', () {
      final set = RecurrenceSet(
        ZonedAnchor(LocalDateTime.of(2026, 10, 5, 9, 0), _berlin),
        rules: <RecurrenceRule>[
          RecurrenceRule.parse('FREQ=DAILY;COUNT=6'),
          RecurrenceRule.parse('FREQ=DAILY;COUNT=2'),
        ],
        dates: <LocalDateTime>[LocalDateTime.of(2026, 10, 20, 9, 0)],
        exceptions: <LocalDateTime>[LocalDateTime.of(2026, 10, 9, 9, 0)],
      );
      final (RecurrenceSet head, RecurrenceSet tail) = set.splitAt(
        LocalDateTime.of(2026, 10, 8, 9, 0),
      );

      expect(_locals(head.occurrences()), <String>[
        '2026-10-05T09:00',
        '2026-10-06T09:00',
        '2026-10-07T09:00',
      ]);
      expect(_locals(tail.occurrences()), <String>[
        '2026-10-08T09:00',
        '2026-10-10T09:00',
        '2026-10-20T09:00',
      ]);
      expect(tail.rules, hasLength(1));
      expect(tail.rules.single.count, 3);
    });

    test('move a series and what pins it', () {
      final set = RecurrenceSet(
        ZonedAnchor(LocalDateTime.of(2026, 10, 5, 9, 0), _berlin),
        rules: <RecurrenceRule>[
          RecurrenceRule.parse(
            'FREQ=WEEKLY;BYDAY=MO,TH;UNTIL=20261231T225959Z',
          ),
        ],
        dates: <LocalDateTime>[LocalDateTime.of(2026, 10, 20, 9, 0)],
        exceptions: <LocalDateTime>[LocalDateTime.of(2026, 10, 8, 9, 0)],
      );
      final RecurrenceSet moved = set.movedTo(
        LocalDateTime.of(2026, 10, 6, 10, 30),
      );

      expect(moved.anchor.local, LocalDateTime.of(2026, 10, 6, 10, 30));
      expect(
        moved.rules.single.byDay.map((it) => it.toString()).toList(),
        <String>['TU', 'TH'],
      );
      expect(moved.dates.single, LocalDateTime.of(2026, 10, 21, 10, 30));
      expect(moved.exceptions.single, LocalDateTime.of(2026, 10, 9, 10, 30));
      expect(
        moved.rules.single.until,
        RecurrenceUntilInstant(Instant.parse('2027-01-02T00:29:59Z')),
      );
      final monthly = RecurrenceSet(
        DateAnchor(LocalDate(2026, 1, 15)),
        rules: <RecurrenceRule>[
          RecurrenceRule.parse('FREQ=MONTHLY;BYMONTHDAY=15;UNTIL=20261231'),
          RecurrenceRule.parse('FREQ=YEARLY;BYMONTH=1'),
        ],
      );
      final RecurrenceSet monthlyMoved = monthly.movedTo(
        LocalDateTime.of(2026, 2, 16, 0, 0),
      );
      expect(monthlyMoved.rules[0].byMonthDay, <int>[16]);
      expect(
        monthlyMoved.rules[0].until,
        RecurrenceUntilDate(LocalDate(2027, 2, 1)),
      );
      expect(monthlyMoved.rules[1].byMonth, <int>[2]);
      final floating = RecurrenceSet(
        FloatingAnchor(LocalDateTime.of(2026, 1, 1, 9, 0)),
        rules: <RecurrenceRule>[
          RecurrenceRule.parse('FREQ=DAILY;UNTIL=20260110T090000'),
        ],
      );
      expect(
        floating.movedTo(LocalDateTime.of(2026, 1, 1, 8, 0)).rules.single.until,
        RecurrenceUntilLocal(LocalDateTime.of(2026, 1, 10, 8, 0)),
      );
    });

    test('compare as values', () {
      final RecurrenceSet set = _zoned('2026-10-05T09:00', 'FREQ=DAILY');

      expect(set, _zoned('2026-10-05T09:00', 'FREQ=DAILY'));
      expect(set.hashCode, _zoned('2026-10-05T09:00', 'FREQ=DAILY').hashCode);
      expect(set == _zoned('2026-10-05T09:00', 'FREQ=WEEKLY'), isFalse);
      expect(set == RecurrenceSet(set.anchor), isFalse);
      expect(
        set ==
            RecurrenceSet(
              set.anchor,
              rules: set.rules,
              exceptions: <LocalDateTime>[set.anchor.local],
            ),
        isFalse,
      );
      expect(set.toString(), startsWith('RecurrenceSet(ZonedAnchor('));
      final occurrence = RecurrenceOccurrence(
        LocalDateTime.of(2026, 1, 1, 9, 0),
      );
      expect(occurrence.toString(), '2026-01-01T09:00');
      expect(
        occurrence,
        RecurrenceOccurrence(LocalDateTime.of(2026, 1, 1, 9, 0)),
      );
      expect(
        occurrence.hashCode,
        RecurrenceOccurrence(LocalDateTime.of(2026, 1, 1, 9, 0)).hashCode,
      );
      expect(
        occurrence.compareTo(
          RecurrenceOccurrence(LocalDateTime.of(2026, 1, 2, 9, 0)),
        ),
        isNegative,
      );
      expect(
        set.occurrences().first.toString(),
        '2026-10-05T09:00 (2026-10-05T07:00:00Z)',
      );
    });
  });
}
