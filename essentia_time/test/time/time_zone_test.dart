/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_time/essentia_time.dart';
import 'package:test/test.dart';

import 'fixed_clock.dart';

/// Covers time zones: naming, conversion both ways, the gaps and overlaps
/// of daylight saving time and zones of own rules.
void main() {
  final TimeZone berlin = TimeZone.of('Europe/Berlin');
  final TimeZone santiago = TimeZone.of('America/Santiago');

  group('naming', () {
    test('reads region identifiers and links', () {
      expect(berlin.id, 'Europe/Berlin');
      expect(TimeZone.of('US/Eastern').id, 'US/Eastern');
      expect(
        TimeZone.of('US/Eastern').rules,
        TimeZone.of('America/New_York').rules,
      );
      expect(TimeZone.availableZoneIds, contains('Europe/Berlin'));
      expect(TimeZone.availableZoneIds, contains('US/Eastern'));
      expect(TimeZone.availableZoneIds.length, greaterThan(590));
      expect(TimeZone.databaseVersion, '2026e');
    });

    test('reads fixed offsets with and without a prefix', () {
      expect(TimeZone.of('UTC'), TimeZone.utc);
      expect(TimeZone.of('Z').id, 'Z');
      expect(TimeZone.of('GMT').id, 'GMT');
      expect(TimeZone.of('+02:00').id, '+02:00');
      expect(TimeZone.of('+5').id, '+05:00');
      expect(TimeZone.of('UTC+2').id, 'UTC+02:00');
      expect(TimeZone.of('GMT-03:30').id, 'GMT-03:30');
      expect(TimeZone.of('UT+0').id, 'UT');
      expect(
        (TimeZone.of('UTC+2') as FixedOffsetTimeZone).offset,
        UtcOffset(hours: 2),
      );
    });

    test('refuses identifiers it does not know', () {
      expect(
        () => TimeZone.of('Nowhere/City'),
        throwsA(isA<IllegalTimeZoneException>()),
      );
      expect(
        () => TimeZone.of('+25:00'),
        throwsA(isA<IllegalTimeZoneException>()),
      );
      expect(TimeZone.ofOrNull('UTC+x'), isNull);
      expect(TimeZone.ofOrNull('Asia/Tokyo')?.id, 'Asia/Tokyo');
      expect(
        const IllegalTimeZoneException('bad').toString(),
        'IllegalTimeZoneException: bad',
      );
    });

    test('names the zone of the system', () {
      expect(TimeZone.currentSystemDefault().id, isNotEmpty);
    });

    test('compares by identifier', () {
      expect(TimeZone.of('Europe/Berlin'), berlin);
      expect(berlin.hashCode, TimeZone.of('Europe/Berlin').hashCode);
      expect(berlin == TimeZone.of('Europe/Paris'), isFalse);
      expect(berlin.toString(), 'Europe/Berlin');
    });
  });

  group('conversion', () {
    test('turns moments into local times and back', () {
      final instant = Instant.parse('2026-07-01T10:00:00.5Z');
      final LocalDateTime local = berlin.toLocalDateTime(instant);

      expect(local, LocalDateTime.of(2026, 7, 1, 12, 0, 0, 500000000));
      expect(berlin.toInstant(local), instant);
      expect(berlin.offsetAt(instant), UtcOffset(hours: 2));
      expect(
        TimeZone.utc.toLocalDateTime(Instant.fromEpochSeconds(-1)),
        LocalDateTime.of(1969, 12, 31, 23, 59, 59),
      );
    });

    test('moves a skipped local time forward by the gap', () {
      final skipped = LocalDateTime.of(2026, 3, 29, 2, 30);
      final ZoneOffsetInfo info = berlin.offsetInfo(skipped);

      expect(info, isA<GapOffsetInfo>());
      expect(
        (info as GapOffsetInfo).transition.instant,
        Instant.parse('2026-03-29T01:00:00Z'),
      );
      expect(berlin.toInstant(skipped), Instant.parse('2026-03-29T01:30:00Z'));
      expect(
        berlin.toInstant(skipped, resolution: ZoneResolution.laterOffset),
        Instant.parse('2026-03-29T01:30:00Z'),
      );
      expect(
        () => berlin.toInstant(skipped, resolution: ZoneResolution.strict),
        throwsA(isA<DateTimeArithmeticException>()),
      );
    });

    test('chooses an offset for a repeated local time', () {
      final repeated = LocalDateTime.of(2026, 10, 25, 2, 30);

      expect(berlin.offsetInfo(repeated), isA<OverlapOffsetInfo>());
      expect(berlin.toInstant(repeated), Instant.parse('2026-10-25T00:30:00Z'));
      expect(
        repeated.toInstant(berlin, resolution: ZoneResolution.laterOffset),
        Instant.parse('2026-10-25T01:30:00Z'),
      );
      expect(
        berlin.toInstant(repeated, preferredOffset: UtcOffset(hours: 1)),
        Instant.parse('2026-10-25T01:30:00Z'),
      );
      expect(
        berlin.toInstant(repeated, preferredOffset: UtcOffset(hours: 5)),
        Instant.parse('2026-10-25T00:30:00Z'),
      );
      expect(
        () => berlin.toInstant(repeated, resolution: ZoneResolution.strict),
        throwsA(isA<DateTimeArithmeticException>()),
      );
      expect(
        const DateTimeArithmeticException('no').toString(),
        'DateTimeArithmeticException: no',
      );
    });

    test('starts a day at the first moment its clocks show', () {
      expect(
        LocalDate(2026, 9, 6).atStartOfDayIn(santiago),
        Instant.parse('2026-09-06T04:00:00Z'),
      );
      expect(
        santiago.toInstant(LocalDateTime.of(2026, 9, 6, 0, 30)),
        Instant.parse('2026-09-06T04:30:00Z'),
      );
      expect(
        LocalDate(2026, 4, 4).atStartOfDayIn(santiago),
        Instant.parse('2026-04-04T03:00:00Z'),
      );
      expect(
        santiago.toInstant(
          LocalDateTime.of(2026, 4, 4, 23, 30),
          resolution: ZoneResolution.laterOffset,
        ),
        Instant.parse('2026-04-05T03:30:00Z'),
      );
    });

    test('reads the date and time from a clock', () {
      final clock = FixedClock(Instant.parse('2026-10-09T22:30:00Z'));

      expect(clock.todayIn(berlin), LocalDate(2026, 10, 10));
      expect(clock.nowIn(TimeZone.utc), LocalDateTime.of(2026, 10, 9, 22, 30));
    });
  });

  group('zones of own rules', () {
    test('keeps a fixed rule a fixed zone', () {
      final TimeZone zone = TimeZone.fromRules(
        'Custom/Fixed',
        ZoneRules.fixed(UtcOffset(hours: 3)),
      );

      expect(zone, isA<FixedOffsetTimeZone>());
      expect(zone.id, 'Custom/Fixed');
      expect(zone.offsetAt(Instant.epoch), UtcOffset(hours: 3));
      expect(zone.rules.isFixed, isTrue);
    });

    test('follows recurring rules', () {
      final TimeZone zone = TimeZone.fromRules(
        'Custom/Summer',
        ZoneRules(
          initialOffset: UtcOffset(hours: 1),
          recurring: RecurringZoneRule(
            standardOffset: UtcOffset(hours: 1),
            rules: <ZoneTransitionRule>[
              ZoneTransitionRule(
                month: Month.march,
                day: -1,
                dayOfWeek: DayOfWeek.sunday,
                onOrBefore: true,
                timeOfDay: const Duration(hours: 1),
                definition: ZoneTimeDefinition.utc,
                offsetAfter: UtcOffset(hours: 2),
              ),
              ZoneTransitionRule(
                month: Month.october,
                day: -1,
                dayOfWeek: DayOfWeek.sunday,
                onOrBefore: true,
                timeOfDay: const Duration(hours: 1),
                definition: ZoneTimeDefinition.utc,
                offsetAfter: UtcOffset(hours: 1),
              ),
            ],
          ),
        ),
      );

      for (final instant in <Instant>[
        Instant.parse('2000-07-01T00:00:00Z'),
        Instant.parse('2026-03-29T00:59:59Z'),
        Instant.parse('2026-03-29T01:00:00Z'),
        Instant.parse('2026-10-25T01:00:00Z'),
        Instant.parse('2300-08-01T00:00:00Z'),
      ]) {
        expect(zone.offsetAt(instant), berlin.offsetAt(instant));
      }
    });
  });
}
