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

import 'package:essentia_time/essentia_time.dart';
import 'package:essentia_time/recurrence.dart';
import 'package:test/test.dart';

/// The zone of the examples of RFC 5545.
final TimeZone _newYork = TimeZone.of('America/New_York');

/// The examples of RFC 5545, section 3.8.5.3: the start, the rule, the
/// exceptions and the first repetitions the RFC lists, as local times in
/// New York.
final _examples = <(String, String, String, List<String>, List<String>)>[
  (
    'daily for 10 occurrences',
    '1997-09-02T09:00',
    'FREQ=DAILY;COUNT=10',
    <String>[],
    <String>[
      for (var day = 2; day <= 11; day += 1)
        '1997-09-${'$day'.padLeft(2, '0')}T09:00',
    ],
  ),
  (
    'every other day',
    '1997-09-02T09:00',
    'FREQ=DAILY;INTERVAL=2',
    <String>[],
    <String>['1997-09-02T09:00', '1997-09-04T09:00', '1997-09-06T09:00'],
  ),
  (
    'every 10 days, 5 occurrences',
    '1997-09-02T09:00',
    'FREQ=DAILY;INTERVAL=10;COUNT=5',
    <String>[],
    <String>[
      '1997-09-02T09:00',
      '1997-09-12T09:00',
      '1997-09-22T09:00',
      '1997-10-02T09:00',
      '1997-10-12T09:00',
    ],
  ),
  (
    'weekly for 10 occurrences',
    '1997-09-02T09:00',
    'FREQ=WEEKLY;COUNT=10',
    <String>[],
    <String>[
      '1997-09-02T09:00',
      '1997-09-09T09:00',
      '1997-09-16T09:00',
      '1997-09-23T09:00',
      '1997-09-30T09:00',
      '1997-10-07T09:00',
      '1997-10-14T09:00',
      '1997-10-21T09:00',
      '1997-10-28T09:00',
      '1997-11-04T09:00',
    ],
  ),
  (
    'weekly on Tuesday and Thursday for five weeks',
    '1997-09-02T09:00',
    'FREQ=WEEKLY;UNTIL=19971007T000000Z;WKST=SU;BYDAY=TU,TH',
    <String>[],
    <String>[
      '1997-09-02T09:00',
      '1997-09-04T09:00',
      '1997-09-09T09:00',
      '1997-09-11T09:00',
      '1997-09-16T09:00',
      '1997-09-18T09:00',
      '1997-09-23T09:00',
      '1997-09-25T09:00',
      '1997-09-30T09:00',
      '1997-10-02T09:00',
    ],
  ),
  (
    'every other week on Monday, Wednesday and Friday',
    '1997-09-01T09:00',
    'FREQ=WEEKLY;INTERVAL=2;UNTIL=19971224T000000Z;WKST=SU;BYDAY=MO,WE,FR',
    <String>[],
    <String>[
      '1997-09-01T09:00',
      '1997-09-03T09:00',
      '1997-09-05T09:00',
      '1997-09-15T09:00',
      '1997-09-17T09:00',
      '1997-09-19T09:00',
      '1997-09-29T09:00',
      '1997-10-01T09:00',
      '1997-10-03T09:00',
      '1997-10-13T09:00',
      '1997-10-15T09:00',
      '1997-10-17T09:00',
      '1997-10-27T09:00',
      '1997-10-29T09:00',
      '1997-10-31T09:00',
      '1997-11-10T09:00',
      '1997-11-12T09:00',
      '1997-11-14T09:00',
      '1997-11-24T09:00',
      '1997-11-26T09:00',
      '1997-11-28T09:00',
      '1997-12-08T09:00',
      '1997-12-10T09:00',
      '1997-12-12T09:00',
      '1997-12-22T09:00',
    ],
  ),
  (
    'every other week on Tuesday and Thursday, 8 occurrences',
    '1997-09-02T09:00',
    'FREQ=WEEKLY;INTERVAL=2;COUNT=8;WKST=SU;BYDAY=TU,TH',
    <String>[],
    <String>[
      '1997-09-02T09:00',
      '1997-09-04T09:00',
      '1997-09-16T09:00',
      '1997-09-18T09:00',
      '1997-09-30T09:00',
      '1997-10-02T09:00',
      '1997-10-14T09:00',
      '1997-10-16T09:00',
    ],
  ),
  (
    'monthly on the first Friday for 10 occurrences',
    '1997-09-05T09:00',
    'FREQ=MONTHLY;COUNT=10;BYDAY=1FR',
    <String>[],
    <String>[
      '1997-09-05T09:00',
      '1997-10-03T09:00',
      '1997-11-07T09:00',
      '1997-12-05T09:00',
      '1998-01-02T09:00',
      '1998-02-06T09:00',
      '1998-03-06T09:00',
      '1998-04-03T09:00',
      '1998-05-01T09:00',
      '1998-06-05T09:00',
    ],
  ),
  (
    'every other month on the first and last Sunday',
    '1997-09-07T09:00',
    'FREQ=MONTHLY;INTERVAL=2;COUNT=10;BYDAY=1SU,-1SU',
    <String>[],
    <String>[
      '1997-09-07T09:00',
      '1997-09-28T09:00',
      '1997-11-02T09:00',
      '1997-11-30T09:00',
      '1998-01-04T09:00',
      '1998-01-25T09:00',
      '1998-03-01T09:00',
      '1998-03-29T09:00',
      '1998-05-03T09:00',
      '1998-05-31T09:00',
    ],
  ),
  (
    'monthly on the second-to-last Monday',
    '1997-09-22T09:00',
    'FREQ=MONTHLY;COUNT=6;BYDAY=-2MO',
    <String>[],
    <String>[
      '1997-09-22T09:00',
      '1997-10-20T09:00',
      '1997-11-17T09:00',
      '1997-12-22T09:00',
      '1998-01-19T09:00',
      '1998-02-16T09:00',
    ],
  ),
  (
    'monthly on the third-to-last day',
    '1997-09-28T09:00',
    'FREQ=MONTHLY;BYMONTHDAY=-3',
    <String>[],
    <String>[
      '1997-09-28T09:00',
      '1997-10-29T09:00',
      '1997-11-28T09:00',
      '1997-12-29T09:00',
      '1998-01-29T09:00',
      '1998-02-26T09:00',
    ],
  ),
  (
    'monthly on the 2nd and 15th',
    '1997-09-02T09:00',
    'FREQ=MONTHLY;COUNT=10;BYMONTHDAY=2,15',
    <String>[],
    <String>[
      '1997-09-02T09:00',
      '1997-09-15T09:00',
      '1997-10-02T09:00',
      '1997-10-15T09:00',
      '1997-11-02T09:00',
      '1997-11-15T09:00',
      '1997-12-02T09:00',
      '1997-12-15T09:00',
      '1998-01-02T09:00',
      '1998-01-15T09:00',
    ],
  ),
  (
    'monthly on the first and last day',
    '1997-09-30T09:00',
    'FREQ=MONTHLY;COUNT=10;BYMONTHDAY=1,-1',
    <String>[],
    <String>[
      '1997-09-30T09:00',
      '1997-10-01T09:00',
      '1997-10-31T09:00',
      '1997-11-01T09:00',
      '1997-11-30T09:00',
      '1997-12-01T09:00',
      '1997-12-31T09:00',
      '1998-01-01T09:00',
      '1998-01-31T09:00',
      '1998-02-01T09:00',
    ],
  ),
  (
    'every 18 months on the 10th to 15th',
    '1997-09-10T09:00',
    'FREQ=MONTHLY;INTERVAL=18;COUNT=10;BYMONTHDAY=10,11,12,13,14,15',
    <String>[],
    <String>[
      '1997-09-10T09:00',
      '1997-09-11T09:00',
      '1997-09-12T09:00',
      '1997-09-13T09:00',
      '1997-09-14T09:00',
      '1997-09-15T09:00',
      '1999-03-10T09:00',
      '1999-03-11T09:00',
      '1999-03-12T09:00',
      '1999-03-13T09:00',
    ],
  ),
  (
    'every Tuesday, every other month',
    '1997-09-02T09:00',
    'FREQ=MONTHLY;INTERVAL=2;BYDAY=TU',
    <String>[],
    <String>[
      '1997-09-02T09:00',
      '1997-09-09T09:00',
      '1997-09-16T09:00',
      '1997-09-23T09:00',
      '1997-09-30T09:00',
      '1997-11-04T09:00',
      '1997-11-11T09:00',
      '1997-11-18T09:00',
      '1997-11-25T09:00',
      '1998-01-06T09:00',
    ],
  ),
  (
    'yearly in June and July',
    '1997-06-10T09:00',
    'FREQ=YEARLY;COUNT=10;BYMONTH=6,7',
    <String>[],
    <String>[
      '1997-06-10T09:00',
      '1997-07-10T09:00',
      '1998-06-10T09:00',
      '1998-07-10T09:00',
      '1999-06-10T09:00',
      '1999-07-10T09:00',
      '2000-06-10T09:00',
      '2000-07-10T09:00',
      '2001-06-10T09:00',
      '2001-07-10T09:00',
    ],
  ),
  (
    'every other year in January, February and March',
    '1997-03-10T09:00',
    'FREQ=YEARLY;INTERVAL=2;COUNT=10;BYMONTH=1,2,3',
    <String>[],
    <String>[
      '1997-03-10T09:00',
      '1999-01-10T09:00',
      '1999-02-10T09:00',
      '1999-03-10T09:00',
      '2001-01-10T09:00',
      '2001-02-10T09:00',
      '2001-03-10T09:00',
      '2003-01-10T09:00',
      '2003-02-10T09:00',
      '2003-03-10T09:00',
    ],
  ),
  (
    'every third year on the 1st, 100th and 200th day',
    '1997-01-01T09:00',
    'FREQ=YEARLY;INTERVAL=3;COUNT=10;BYYEARDAY=1,100,200',
    <String>[],
    <String>[
      '1997-01-01T09:00',
      '1997-04-10T09:00',
      '1997-07-19T09:00',
      '2000-01-01T09:00',
      '2000-04-09T09:00',
      '2000-07-18T09:00',
      '2003-01-01T09:00',
      '2003-04-10T09:00',
      '2003-07-19T09:00',
      '2006-01-01T09:00',
    ],
  ),
  (
    'every 20th Monday of the year',
    '1997-05-19T09:00',
    'FREQ=YEARLY;BYDAY=20MO',
    <String>[],
    <String>['1997-05-19T09:00', '1998-05-18T09:00', '1999-05-17T09:00'],
  ),
  (
    'Monday of week 20',
    '1997-05-12T09:00',
    'FREQ=YEARLY;BYWEEKNO=20;BYDAY=MO',
    <String>[],
    <String>['1997-05-12T09:00', '1998-05-11T09:00', '1999-05-17T09:00'],
  ),
  (
    'every Thursday in March',
    '1997-03-13T09:00',
    'FREQ=YEARLY;BYMONTH=3;BYDAY=TH',
    <String>[],
    <String>[
      '1997-03-13T09:00',
      '1997-03-20T09:00',
      '1997-03-27T09:00',
      '1998-03-05T09:00',
      '1998-03-12T09:00',
      '1998-03-19T09:00',
      '1998-03-26T09:00',
      '1999-03-04T09:00',
    ],
  ),
  (
    'every Thursday in June, July and August',
    '1997-06-05T09:00',
    'FREQ=YEARLY;BYDAY=TH;BYMONTH=6,7,8',
    <String>[],
    <String>[
      '1997-06-05T09:00',
      '1997-06-12T09:00',
      '1997-06-19T09:00',
      '1997-06-26T09:00',
      '1997-07-03T09:00',
      '1997-07-10T09:00',
      '1997-07-17T09:00',
      '1997-07-24T09:00',
      '1997-07-31T09:00',
      '1997-08-07T09:00',
      '1997-08-14T09:00',
      '1997-08-21T09:00',
      '1997-08-28T09:00',
      '1998-06-04T09:00',
    ],
  ),
  (
    'every Friday the 13th',
    '1997-09-02T09:00',
    'FREQ=MONTHLY;BYDAY=FR;BYMONTHDAY=13',
    <String>['1997-09-02T09:00'],
    <String>[
      '1998-02-13T09:00',
      '1998-03-13T09:00',
      '1998-11-13T09:00',
      '1999-08-13T09:00',
      '2000-10-13T09:00',
    ],
  ),
  (
    'the first Saturday after the first Sunday',
    '1997-09-13T09:00',
    'FREQ=MONTHLY;BYDAY=SA;BYMONTHDAY=7,8,9,10,11,12,13',
    <String>[],
    <String>[
      '1997-09-13T09:00',
      '1997-10-11T09:00',
      '1997-11-08T09:00',
      '1997-12-13T09:00',
      '1998-01-10T09:00',
      '1998-02-07T09:00',
      '1998-03-07T09:00',
      '1998-04-11T09:00',
      '1998-05-09T09:00',
      '1998-06-13T09:00',
    ],
  ),
  (
    'every four years, election day',
    '1996-11-05T09:00',
    'FREQ=YEARLY;INTERVAL=4;BYMONTH=11;BYDAY=TU;BYMONTHDAY=2,3,4,5,6,7,8',
    <String>[],
    <String>['1996-11-05T09:00', '2000-11-07T09:00', '2004-11-02T09:00'],
  ),
  (
    'the third of Tuesday, Wednesday or Thursday',
    '1997-09-04T09:00',
    'FREQ=MONTHLY;COUNT=3;BYDAY=TU,WE,TH;BYSETPOS=3',
    <String>[],
    <String>['1997-09-04T09:00', '1997-10-07T09:00', '1997-11-06T09:00'],
  ),
  (
    'the second-to-last weekday',
    '1997-09-29T09:00',
    'FREQ=MONTHLY;BYDAY=MO,TU,WE,TH,FR;BYSETPOS=-2',
    <String>[],
    <String>[
      '1997-09-29T09:00',
      '1997-10-30T09:00',
      '1997-11-27T09:00',
      '1997-12-30T09:00',
      '1998-01-29T09:00',
      '1998-02-26T09:00',
      '1998-03-30T09:00',
    ],
  ),
  (
    'every 3 hours from 9 to 17',
    '1997-09-02T09:00',
    'FREQ=HOURLY;INTERVAL=3;UNTIL=19970902T210000Z',
    <String>[],
    <String>['1997-09-02T09:00', '1997-09-02T12:00', '1997-09-02T15:00'],
  ),
  (
    'every 15 minutes, 6 occurrences',
    '1997-09-02T09:00',
    'FREQ=MINUTELY;INTERVAL=15;COUNT=6',
    <String>[],
    <String>[
      '1997-09-02T09:00',
      '1997-09-02T09:15',
      '1997-09-02T09:30',
      '1997-09-02T09:45',
      '1997-09-02T10:00',
      '1997-09-02T10:15',
    ],
  ),
  (
    'every hour and a half, 4 occurrences',
    '1997-09-02T09:00',
    'FREQ=MINUTELY;INTERVAL=90;COUNT=4',
    <String>[],
    <String>[
      '1997-09-02T09:00',
      '1997-09-02T10:30',
      '1997-09-02T12:00',
      '1997-09-02T13:30',
    ],
  ),
  (
    'every 20 minutes from 9 to 16:40, daily',
    '1997-09-02T09:00',
    'FREQ=DAILY;BYHOUR=9,10,11,12,13,14,15,16;BYMINUTE=0,20,40',
    <String>[],
    <String>[
      '1997-09-02T09:00',
      '1997-09-02T09:20',
      '1997-09-02T09:40',
      '1997-09-02T10:00',
    ],
  ),
  (
    'every 20 minutes from 9 to 16:40, minutely',
    '1997-09-02T09:00',
    'FREQ=MINUTELY;INTERVAL=20;BYHOUR=9,10,11,12,13,14,15,16',
    <String>[],
    <String>[
      '1997-09-02T09:00',
      '1997-09-02T09:20',
      '1997-09-02T09:40',
      '1997-09-02T10:00',
    ],
  ),
  (
    'weeks starting on Monday',
    '1997-08-05T09:00',
    'FREQ=WEEKLY;INTERVAL=2;COUNT=4;BYDAY=TU,SU;WKST=MO',
    <String>[],
    <String>[
      '1997-08-05T09:00',
      '1997-08-10T09:00',
      '1997-08-19T09:00',
      '1997-08-24T09:00',
    ],
  ),
  (
    'weeks starting on Sunday',
    '1997-08-05T09:00',
    'FREQ=WEEKLY;INTERVAL=2;COUNT=4;BYDAY=TU,SU;WKST=SU',
    <String>[],
    <String>[
      '1997-08-05T09:00',
      '1997-08-17T09:00',
      '1997-08-19T09:00',
      '1997-08-31T09:00',
    ],
  ),
  (
    'the 30th of February is skipped',
    '2007-01-15T09:00',
    'FREQ=MONTHLY;BYMONTHDAY=15,30;COUNT=5',
    <String>[],
    <String>[
      '2007-01-15T09:00',
      '2007-01-30T09:00',
      '2007-02-15T09:00',
      '2007-03-15T09:00',
      '2007-03-30T09:00',
    ],
  ),
];

/// Checks the expansion against the examples of RFC 5545.
void main() {
  for (final (
        String name,
        String start,
        String rule,
        List<String> exceptions,
        List<String> expected,
      )
      in _examples) {
    test('RFC 5545: $name', () {
      final set = RecurrenceSet(
        ZonedAnchor(LocalDateTime.parse(start), _newYork),
        rules: <RecurrenceRule>[RecurrenceRule.parse(rule)],
        exceptions: exceptions.map(LocalDateTime.parse).toList(),
      );

      expect(
        set
            .occurrences()
            .take(expected.length)
            .map((it) => it.local.toString())
            .toList(),
        expected,
      );
    });
  }

  test('RFC 5545: daily until December 24th makes 113', () {
    final set = RecurrenceSet(
      ZonedAnchor(LocalDateTime.of(1997, 9, 2, 9, 0), _newYork),
      rules: <RecurrenceRule>[
        RecurrenceRule.parse('FREQ=DAILY;UNTIL=19971224T000000Z'),
      ],
    );

    expect(set.occurrences().length, 113);
    expect(set.occurrences().last.local, LocalDateTime.of(1997, 12, 23, 9, 0));
  });

  test('RFC 5545: every day in January for three years, two ways', () {
    final anchor = ZonedAnchor(LocalDateTime.of(1998, 1, 1, 9, 0), _newYork);
    final yearly = RecurrenceSet(
      anchor,
      rules: <RecurrenceRule>[
        RecurrenceRule.parse(
          'FREQ=YEARLY;UNTIL=20000131T140000Z;BYMONTH=1;'
          'BYDAY=SU,MO,TU,WE,TH,FR,SA',
        ),
      ],
    );
    final daily = RecurrenceSet(
      anchor,
      rules: <RecurrenceRule>[
        RecurrenceRule.parse('FREQ=DAILY;UNTIL=20000131T140000Z;BYMONTH=1'),
      ],
    );

    expect(yearly.occurrences().length, 93);
    expect(daily.occurrences().toList(), yearly.occurrences().toList());
  });

  test('RFC 5545: monthly on the first Friday until December 24th', () {
    final set = RecurrenceSet(
      ZonedAnchor(LocalDateTime.of(1997, 9, 5, 9, 0), _newYork),
      rules: <RecurrenceRule>[
        RecurrenceRule.parse('FREQ=MONTHLY;UNTIL=19971224T000000Z;BYDAY=1FR'),
      ],
    );

    expect(set.occurrences().map((it) => it.date.day).toList(), <int>[
      5,
      3,
      7,
      5,
    ]);
  });

  test('RFC 5545: the moments follow the shifts of the clocks', () {
    final set = RecurrenceSet(
      ZonedAnchor(LocalDateTime.of(1997, 10, 24, 9, 0), _newYork),
      rules: <RecurrenceRule>[RecurrenceRule.parse('FREQ=DAILY;COUNT=5')],
    );
    final List<RecurrenceOccurrence> list = set.occurrences().toList();

    expect(list.first.instant, Instant.parse('1997-10-24T13:00:00Z'));
    expect(list.last.instant, Instant.parse('1997-10-28T14:00:00Z'));
  });
}
