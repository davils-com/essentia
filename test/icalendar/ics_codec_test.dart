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

part '_fixtures.dart';

/// The codec of every test, stamping at a fixed time.
final _codec = IcsCodec(
  clock: TestScheduler(start: Instant.parse('2026-10-09T12:00:00Z')),
);

/// Covers the iCalendar codec on files of real-world shapes, round trips,
/// time zones and strict and lenient reads.
void main() {
  final TimeZone berlin = TimeZone.of('Europe/Berlin');

  group('reading a web calendar export', () {
    final IcsCalendar calendar = _codec.decode(_webExport).calendar;

    test('reads the calendar and keeps what it does not know', () {
      expect(calendar.productId, '-//Example//Web Calendar 70.9054//EN');
      expect(calendar.method, 'PUBLISH');
      expect(calendar.scale, 'GREGORIAN');
      expect(calendar.name, 'Team');
      expect(calendar.events, hasLength(3));
      expect(calendar.todos, isEmpty);
      expect(calendar.entries, hasLength(3));
      expect(calendar.timeZones.single.id, 'Europe/Berlin');
      expect(
        calendar.properties.single,
        IcsProperty('X-WR-TIMEZONE', 'Europe/Berlin'),
      );
      expect(calendar.toString(), 'IcsCalendar(Team, 3 events, 0 todos)');
    });

    test('reads an event with everything', () {
      final IcsEvent standup = calendar.events.first;

      expect(standup.uid, 'standup@example.com');
      expect(
        standup.start,
        IcsZonedDateTime(LocalDateTime.of(2026, 10, 5, 9, 30), 'Europe/Berlin'),
      );
      expect(standup.end?.local, LocalDateTime.of(2026, 10, 5, 10, 0));
      expect(standup.summary, 'Stand-up');
      expect(
        standup.description,
        'Daily status, blockers; plans.\nJoin on time.',
      );
      expect(standup.status, IcsEventStatus.confirmed);
      expect(standup.transparency, IcsTransparency.opaque);
      expect(standup.sequence, 2);
      expect(standup.stamp, Instant.parse('2026-10-01T08:00:00Z'));
      expect(standup.created, Instant.parse('2026-09-01T10:00:00Z'));
      expect(standup.organizer?.email, 'ada@example.com');
      expect(standup.organizer?.name, 'Ada Lovelace');
      expect(standup.attendees, hasLength(2));
      final IcsAttendee grace = standup.attendees.first;
      expect(grace.email, 'grace@example.com');
      expect(grace.name, 'Grace Hopper');
      expect(grace.role, IcsRole.required);
      expect(grace.participation, IcsParticipation.accepted);
      expect(grace.userType, IcsUserType.individual);
      expect(grace.rsvp, isTrue);
      expect(standup.attendees.last.userType, IcsUserType.room);
      expect(standup.rules.single.toString(), 'FREQ=WEEKLY;BYDAY=MO,WE');
      expect(
        standup.exceptions.single.local,
        LocalDateTime.of(2026, 10, 7, 9, 30),
      );
      expect(
        standup.alarms.single.trigger,
        IcsRelativeTrigger(DateTimePeriod(minutes: -10)),
      );
      expect(standup.alarms.single.action, IcsAlarmAction.display);
      expect(standup.properties.single.name, 'X-EXAMPLE-CONFERENCE');
      expect(standup.toString(), contains('standup@example.com'));
    });

    test('reads a moved occurrence and a whole-day event', () {
      final IcsEvent moved = calendar.events[1];
      final IcsEvent holidays = calendar.events[2];

      expect(moved.recurrenceId?.local, LocalDateTime.of(2026, 10, 12, 9, 30));
      expect(moved.thisAndFuture, isFalse);
      expect(holidays.start, IcsDate(LocalDate(2026, 12, 24)));
      expect(holidays.end, IcsDate(LocalDate(2026, 12, 27)));
      expect(holidays.categories, <String>['Holiday', 'Team']);
      expect(holidays.transparency, IcsTransparency.transparent);
    });

    test('expands the series in the zone of its start', () {
      final RecurrenceSet set = calendar.events.first.recurrenceSet(
        calendar.zones.call,
      )!;
      final List<RecurrenceOccurrence> week = set.occurrencesBetween(
        LocalDateTime.of(2026, 10, 5, 0, 0),
        LocalDateTime.of(2026, 10, 19, 0, 0),
      );

      expect(week.map((it) => it.local.day).toList(), <int>[5, 12, 14]);
      expect(week.first.instant, Instant.parse('2026-10-05T07:30:00Z'));
      expect(
        calendar.events[2].recurrenceSet(calendar.zones.call)?.anchor,
        DateAnchor(LocalDate(2026, 12, 24)),
      );
    });
  });

  group('reading a meeting request', () {
    final IcsCalendar calendar = _codec.decode(_mailRequest).calendar;
    final IcsEvent meeting = calendar.events.single;

    test('reads the request and its reminder', () {
      expect(calendar.method, 'REQUEST');
      expect(meeting.summary, 'Planung Q4');
      expect(meeting.location, 'Raum 204');
      expect(meeting.priority, 5);
      expect(meeting.classification, IcsClassification.public);
      expect(meeting.attendees.single.role, IcsRole.optional);
      expect(
        meeting.attendees.single.participation,
        IcsParticipation.needsAction,
      );
      expect(
        meeting.alarms.single.trigger,
        IcsRelativeTrigger(DateTimePeriod(minutes: -15)),
      );
      expect(
        meeting.properties.map((it) => it.name),
        contains('X-MICROSOFT-CDO-BUSYSTATUS'),
      );
    });

    test('follows a zone named the Windows way through its description', () {
      final IcsZoneResolver zones = calendar.zones;
      final TimeZone? zone = zones('W. Europe Standard Time');

      expect(zone, isNotNull);
      expect(
        meeting.start!.toInstant(zones.call),
        Instant.parse('2026-10-20T12:00:00Z'),
      );
      for (final instant in <Instant>[
        Instant.parse('2026-03-29T00:59:59Z'),
        Instant.parse('2026-03-29T01:00:00Z'),
        Instant.parse('2026-10-25T00:59:59Z'),
        Instant.parse('2026-10-25T01:00:00Z'),
        Instant.parse('2040-07-01T00:00:00Z'),
      ]) {
        expect(
          zone!.offsetAt(instant),
          berlin.offsetAt(instant),
          reason: '$instant',
        );
      }
      expect(zones('Nowhere Standard Time'), isNull);
      expect(zones.unresolved, <String>['Nowhere Standard Time']);
    });
  });

  group('reading a list of to-dos', () {
    final IcsCalendar calendar = _codec.decode(_todoList).calendar;

    test('reads to-dos with their state, due date and alarm', () {
      final IcsTodo homework = calendar.todos.first;

      expect(homework.summary, 'Mathe: Aufgaben S. 42');
      expect(homework.status, IcsTodoStatus.inProcess);
      expect(homework.percentComplete, 40);
      expect(homework.priority, 1);
      expect(homework.geo, (52.52, 13.405));
      expect(homework.color, 'crimson');
      expect(homework.url, 'https://school.example.org/hw/7');
      expect(
        homework.due!.toInstant(calendar.zones.call),
        Instant.parse('2026-10-12T06:00:00Z'),
      );
      final IcsAlarm alarm = homework.alarms.single;
      expect(alarm.action, IcsAlarmAction.audio);
      expect(
        alarm.trigger,
        IcsAbsoluteTrigger(Instant.parse('2026-10-11T18:00:00Z')),
      );
      expect(alarm.repeat, 2);
      expect(alarm.repeatEvery, DateTimePeriod(minutes: 10));
      expect(
        calendar.todos.last.completed,
        Instant.parse('2026-10-08T15:00:00Z'),
      );
      expect(calendar.todos.last.status, IcsTodoStatus.completed);
      expect(calendar.todos.first.toString(), contains('homework-7'));
    });

    test('keeps components it does not read', () {
      expect(calendar.components.single.name, 'VJOURNAL');
    });
  });

  group('writing', () {
    test('reads back what it writes, for every fixture', () {
      for (final text in <String>[_webExport, _mailRequest, _todoList]) {
        final IcsCalendar calendar = _codec.decode(text).calendar;
        final IcsCalendar again = _codec
            .decode(_codec.encode(calendar))
            .calendar;

        expect(again.events, calendar.events);
        expect(again.todos, calendar.todos);
        expect(again.components, calendar.components);
        expect(again.name, calendar.name);
      }
    });

    test('writes valid lines, folded, with CRLF', () {
      final String text = _codec.encode(_codec.decode(_webExport).calendar);

      expect(text, startsWith('BEGIN:VCALENDAR\r\nVERSION:2.0\r\n'));
      expect(text, endsWith('END:VCALENDAR\r\n'));
      for (final String line in text.split('\r\n')) {
        expect(line.length, lessThanOrEqualTo(75));
      }
    });

    test('describes every zone of the database it names', () {
      final calendar = IcsCalendar(
        events: <IcsEvent>[
          IcsEvent(
            uid: 'a',
            start: IcsZonedDateTime(
              LocalDateTime.of(2026, 10, 9, 9, 0),
              'America/New_York',
            ),
            end: IcsZonedDateTime(
              LocalDateTime.of(2026, 10, 9, 10, 0),
              'America/New_York',
            ),
            rules: <RecurrenceRule>[RecurrenceRule.parse('FREQ=DAILY')],
            dates: <IcsDateTime>[
              IcsDate(LocalDate(2026, 12, 1)),
              IcsUtcDateTime(Instant.parse('2026-12-02T10:00:00Z')),
              IcsFloatingDateTime(LocalDateTime.of(2026, 12, 3, 9, 0)),
              IcsZonedDateTime(
                LocalDateTime.of(2027, 2, 1, 9, 0),
                'America/New_York',
              ),
              IcsZonedDateTime(
                LocalDateTime.of(2027, 2, 2, 9, 0),
                'Nowhere/Else',
              ),
            ],
            recurrenceId: IcsZonedDateTime(
              LocalDateTime.of(2026, 10, 9, 9, 0),
              'America/New_York',
            ),
            thisAndFuture: true,
          ),
        ],
      );
      final String text = _codec.encode(calendar);
      final IcsCalendar read = _codec.decode(text).calendar;

      expect(read.timeZones.single.id, 'America/New_York');
      expect(text, contains('DTSTAMP:20261009T120000Z'));
      expect(text, contains('RANGE=THISANDFUTURE'));
      expect(read.events.single.thisAndFuture, isTrue);
      expect(read.events.single.dates, calendar.events.single.dates);
      final ZoneRules rules = read.timeZones.single.toZoneRules();
      for (final instant in <Instant>[
        Instant.parse('2026-11-01T05:59:59Z'),
        Instant.parse('2026-11-01T06:00:00Z'),
        Instant.parse('2035-07-01T00:00:00Z'),
      ]) {
        expect(
          rules.offsetAt(instant),
          TimeZone.of('America/New_York').offsetAt(instant),
          reason: '$instant',
        );
      }
    });

    test('writes alarms, attendees and to-dos of every kind', () {
      final calendar = IcsCalendar(
        name: 'Hausaufgaben',
        method: 'PUBLISH',
        scale: 'GREGORIAN',
        todos: <IcsTodo>[
          IcsTodo(
            uid: 'todo',
            stamp: Instant.parse('2026-10-09T12:00:00Z'),
            due: IcsDate(LocalDate(2026, 10, 12)),
            completed: Instant.parse('2026-10-11T12:00:00Z'),
            percentComplete: 100,
            status: IcsTodoStatus.completed,
            summary: 'Essay, part 1; draft',
            organizer: const IcsOrganizer(
              'mailto:teacher@example.org',
              name: 'Ms. Smith',
              sentBy: 'mailto:office@example.org',
            ),
            attendees: <IcsAttendee>[
              IcsAttendee(
                'mailto:pupil@example.org',
                delegatedTo: const <String>['mailto:parent@example.org'],
                delegatedFrom: const <String>['mailto:teacher@example.org'],
                sentBy: 'mailto:parent@example.org',
                members: const <String>['mailto:class-7a@example.org'],
              ),
            ],
            alarms: <IcsAlarm>[
              IcsAlarm(
                action: IcsAlarmAction.email,
                trigger: IcsRelativeTrigger(
                  DateTimePeriod(days: -1),
                  fromEnd: true,
                ),
                summary: 'Due tomorrow',
                description: 'Hand it in',
                repeat: 1,
                repeatEvery: DatePeriod(days: 7),
                attendees: <IcsAttendee>[
                  IcsAttendee('mailto:pupil@example.org'),
                ],
                properties: <IcsProperty>[IcsProperty('X-SNOOZED', 'TRUE')],
              ),
            ],
            created: Instant.parse('2026-10-01T00:00:00Z'),
            lastModified: Instant.parse('2026-10-02T00:00:00Z'),
            sequence: 4,
            priority: 2,
            geo: (1.5, -2.25),
            url: 'https://example.org',
            color: 'teal',
            classification: IcsClassification.private,
            categories: const <String>['Deutsch', 'Essay'],
            location: 'Home',
            description: 'Two pages',
            duration: DateTimePeriod(hours: 2),
            properties: <IcsProperty>[IcsProperty('X-SUBJECT', 'Deutsch')],
            components: <IcsComponent>[IcsComponent('X-PART')],
          ),
        ],
      );
      final IcsCalendar read = _codec.decode(_codec.encode(calendar)).calendar;

      expect(read.todos, calendar.todos);
      expect(read.name, 'Hausaufgaben');
      expect(read.todos.single.hashCode, calendar.todos.single.hashCode);
      expect(read, _codec.decode(_codec.encode(calendar)).calendar);
      expect(
        read.hashCode,
        _codec.decode(_codec.encode(calendar)).calendar.hashCode,
      );
    });
  });

  group('strict and lenient reads', () {
    const broken =
        'BEGIN:VCALENDAR\r\n'
        'VERSION:2.0\r\n'
        'X-WR-TIMEZONE:Europe/Berlin\r\n'
        'BEGIN:VEVENT\r\n'
        'DTSTART:20261009T090000\r\n'
        'DURATION:P1M\r\n'
        'RRULE:FREQ=SOMETIMES\r\n'
        'RDATE;VALUE=PERIOD:20261010T090000Z/PT1H\r\n'
        'SEQUENCE:x\r\n'
        'GEO:north\r\n'
        'BEGIN:VALARM\r\n'
        'ACTION:DISPLAY\r\n'
        'END:VALARM\r\n'
        'END:VEVENT\r\n'
        'BEGIN:VTIMEZONE\r\n'
        'BEGIN:STANDARD\r\n'
        'END:STANDARD\r\n'
        'END:VTIMEZONE\r\n'
        'BEGIN:VTIMEZONE\r\n'
        'TZID:Half\r\n'
        'BEGIN:STANDARD\r\n'
        'DTSTART:19700101T000000\r\n'
        'END:STANDARD\r\n'
        'END:VTIMEZONE\r\n'
        'END:VCALENDAR\r\n'
        'BEGIN:VEVENT\r\n'
        'END:VEVENT\r\n';

    test('a strict read lists every problem at once', () {
      try {
        _codec.decode(broken);
        fail('A broken file was read');
      } on IcsParseException catch (error) {
        expect(error.problems, hasLength(greaterThanOrEqualTo(8)));
        expect(error.toString(), startsWith('IcsParseException ('));
      }
      expect(() => _codec.decode('nothing'), throwsA(isA<IcsParseException>()));
    });

    test('a lenient read reads past them', () {
      final IcsParseResult result = _codec.decode(
        broken,
        options: const IcsParseOptions(lenient: true),
      );
      final IcsEvent event = result.calendar.events.single;

      expect(result.warnings, isNotEmpty);
      expect(result.toString(), startsWith('IcsParseResult(1 calendars'));
      expect(event.uid, 'missing-uid-1');
      expect(
        event.start,
        IcsZonedDateTime(LocalDateTime.of(2026, 10, 9, 9, 0), 'Europe/Berlin'),
      );
      expect(
        event.dates.single,
        IcsUtcDateTime(Instant.parse('2026-10-10T09:00:00Z')),
      );
      expect(event.rules, isEmpty);
      expect(event.alarms, isEmpty);
      expect(event.sequence, isNull);
      expect(result.calendar.timeZones, isEmpty);
      expect(
        IcsParseResult(const <IcsCalendar>[], const <String>[]).calendar.events,
        isEmpty,
      );
      expect(
        const IcsParseOptions(lenient: true),
        const IcsParseOptions(lenient: true),
      );
      expect(
        const IcsParseOptions().hashCode,
        const IcsParseOptions().hashCode,
      );
    });
  });

  group('values', () {
    test('read and write dates, times, durations and offsets', () {
      final property = IcsProperty('DTSTART', '');

      expect(
        parseIcsDateTime('20261009', property),
        IcsDate(LocalDate(2026, 10, 9)),
      );
      expect(
        parseIcsDateTime('20261009T235960Z', property),
        IcsUtcDateTime(Instant.parse('2026-10-09T23:59:59Z')),
      );
      expect(
        () => parseIcsDateTime('2026-10-09', property),
        throwsFormatException,
      );
      expect(parseIcsDuration('P1W'), DatePeriod(days: 7));
      expect(parseIcsDuration('-PT15M'), DateTimePeriod(minutes: -15));
      expect(() => parseIcsDuration('P1Y'), throwsFormatException);
      expect(() => parseIcsDuration('P1M'), throwsFormatException);
      expect(() => parseIcsDuration('1D'), throwsFormatException);
      expect(formatIcsDuration(DatePeriod(days: 14)), 'P2W');
      expect(
        formatIcsDuration(
          DateTimePeriod(days: 1, hours: 1, minutes: 2, seconds: 3),
        ),
        'P1DT1H2M3S',
      );
      expect(formatIcsDuration(DateTimePeriod(minutes: -15)), '-PT15M');
      expect(formatIcsDuration(DateTimePeriod()), 'P0D');
      expect(
        () => formatIcsDuration(DatePeriod(months: 1)),
        throwsArgumentError,
      );
      expect(
        () => formatIcsDuration(DateTimePeriod(days: 1, hours: -1)),
        throwsArgumentError,
      );
      expect(parseIcsOffset('-0530'), UtcOffset(hours: -5, minutes: -30));
      expect(formatIcsOffset(UtcOffset(hours: -5, minutes: -30)), '-0530');
      expect(formatIcsOffset(UtcOffset(minutes: 53, seconds: 28)), '+005328');
    });

    test('compare and describe dates and times of every kind', () {
      final local = LocalDateTime.of(2026, 10, 9, 9, 0);

      expect(
        IcsDate(LocalDate(2026, 10, 9)).hashCode,
        LocalDate(2026, 10, 9).hashCode,
      );
      expect(IcsDate(LocalDate(2026, 10, 9)).toString(), 'IcsDate(2026-10-09)');
      expect(
        const IcsUtcDateTime(Instant.epoch).hashCode,
        Instant.epoch.hashCode,
      );
      expect(const IcsUtcDateTime(Instant.epoch).toString(), contains('1970'));
      expect(
        IcsZonedDateTime(local, 'Europe/Berlin').hashCode,
        IcsZonedDateTime(local, 'Europe/Berlin').hashCode,
      );
      expect(
        IcsZonedDateTime(local, 'Europe/Berlin').toString(),
        contains('Europe/Berlin'),
      );
      expect(IcsFloatingDateTime(local).hashCode, local.hashCode);
      expect(
        IcsFloatingDateTime(local).toString(),
        contains('2026-10-09T09:00'),
      );
      expect(
        IcsDate(LocalDate(2026, 10, 9))
            .toInstant(TimeZone.ofOrNull, floatingZone: berlin),
        Instant.parse('2026-10-08T22:00:00Z'),
      );
      expect(
        IcsFloatingDateTime(local)
            .toInstant(TimeZone.ofOrNull, floatingZone: berlin),
        Instant.parse('2026-10-09T07:00:00Z'),
      );
      expect(
        IcsZonedDateTime(local, 'Nowhere').toInstant(TimeZone.ofOrNull),
        Instant.parse('2026-10-09T09:00:00Z'),
      );
      expect(
        IcsRelativeTrigger(
          DateTimePeriod(minutes: -5),
          fromEnd: true,
        ).toString(),
        contains('end'),
      );
      expect(
        IcsRelativeTrigger(DateTimePeriod(minutes: -5)).hashCode,
        IcsRelativeTrigger(DateTimePeriod(minutes: -5)).hashCode,
      );
      expect(
        const IcsAbsoluteTrigger(Instant.epoch).hashCode,
        Instant.epoch.hashCode,
      );
      expect(
        const IcsAbsoluteTrigger(Instant.epoch).toString(),
        contains('1970'),
      );
      expect(
        const IcsOrganizer('mailto:a@b.c').hashCode,
        const IcsOrganizer('mailto:a@b.c').hashCode,
      );
      expect(const IcsOrganizer('x').email, 'x');
      expect(IcsAttendee('x').email, 'x');
      expect(const IcsOrganizer('x').toString(), contains('x'));
    });
  });

  group('time zones', () {
    test('describe zones of the database and read them back', () {
      for (final id in <String>[
        'Europe/Berlin',
        'Australia/Sydney',
        'Asia/Tokyo',
        'America/Sao_Paulo',
        'Africa/Casablanca',
      ]) {
        final TimeZone zone = TimeZone.of(id);
        final description = IcsTimeZone.fromTimeZone(
          zone,
          from: Instant.parse('2015-01-01T00:00:00Z'),
          until: Instant.parse('2030-01-01T00:00:00Z'),
        );
        final ZoneRules rules = description.toZoneRules();
        for (var month = 0; month < 12 * 14; month += 1) {
          final Instant instant = Instant.parse('2016-01-01T12:00:00Z')
              .plus(month, DateTimeUnit.month, timeZone: TimeZone.utc);
          expect(
            rules.offsetAt(instant),
            zone.offsetAt(instant),
            reason: '$id $instant',
          );
        }
      }
    });

    test('read the shapes yearly rules take', () {
      IcsTimeZone zone(String rule) => IcsTimeZone(
        id: 'Test',
        observances: <IcsTimeZoneObservance>[
          IcsTimeZoneObservance(
            daylight: true,
            start: LocalDateTime.of(2000, 3, 1, 2, 0),
            offsetFrom: UtcOffset.zero,
            offsetTo: UtcOffset(hours: 1),
            rules: <RecurrenceRule>[RecurrenceRule.parse(rule)],
            names: const <String>['TST'],
          ),
          IcsTimeZoneObservance(
            daylight: false,
            start: LocalDateTime.of(2000, 10, 1, 3, 0),
            offsetFrom: UtcOffset(hours: 1),
            offsetTo: UtcOffset.zero,
            rules: <RecurrenceRule>[
              RecurrenceRule.parse('FREQ=YEARLY;BYMONTH=10;BYDAY=1SU'),
            ],
          ),
        ],
      );

      for (final rule in <String>[
        'FREQ=YEARLY;BYMONTH=3;BYDAY=2SU',
        'FREQ=YEARLY;BYMONTH=3;BYDAY=-2SU',
        'FREQ=YEARLY;BYMONTH=3;BYDAY=SU;BYMONTHDAY=8,9,10,11,12,13,14',
        'FREQ=YEARLY;BYMONTH=3;BYMONTHDAY=15',
        'FREQ=YEARLY;BYMONTH=3;BYDAY=SU,MO',
        'FREQ=MONTHLY;BYMONTHDAY=1',
        'FREQ=YEARLY;BYMONTH=3;BYDAY=SU;BYMONTHDAY=1,2',
      ]) {
        final IcsTimeZone description = zone(rule);
        final ZoneRules rules = description.toZoneRules();
        final set = RecurrenceSet(
          FloatingAnchor(description.observances.first.start),
          rules: description.observances.first.rules,
        );
        final RecurrenceOccurrence spring = set.occurrences().firstWhere(
          (it) => it.local.year >= 2050,
        );
        expect(
          rules.offsetAt(spring.local.toInstantAt(UtcOffset.zero)),
          UtcOffset(hours: 1),
          reason: rule,
        );
      }
      expect(
        zone('FREQ=YEARLY;BYMONTH=3;BYDAY=2SU'),
        zone('FREQ=YEARLY;BYMONTH=3;BYDAY=2SU'),
      );
      expect(
        zone('FREQ=YEARLY;BYMONTH=3;BYDAY=2SU').hashCode,
        zone('FREQ=YEARLY;BYMONTH=3;BYDAY=2SU').hashCode,
      );
      expect(
        zone('FREQ=YEARLY;BYMONTH=3;BYDAY=2SU').toString(),
        'IcsTimeZone(Test, 2 observances)',
      );
      expect(
        zone('FREQ=YEARLY;BYMONTH=3;BYDAY=2SU').observances.first.toString(),
        contains('daylight'),
      );
      expect(
        IcsTimeZone(
          id: 'Empty',
          observances: const <IcsTimeZoneObservance>[],
        ).toZoneRules().isFixed,
        isTrue,
      );
    });

    test('describe a fixed zone with one observance', () {
      final description = IcsTimeZone.fromTimeZone(
        TimeZone.of('Asia/Kolkata'),
        from: Instant.parse('2026-01-01T00:00:00Z'),
        until: Instant.parse('2027-01-01T00:00:00Z'),
      );

      expect(
        description.observances.single.offsetTo,
        UtcOffset(hours: 5, minutes: 30),
      );
      expect(
        description.toZoneRules().offsetAt(Instant.epoch),
        UtcOffset(hours: 5, minutes: 30),
      );
    });
  });
}
