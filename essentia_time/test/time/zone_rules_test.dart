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
import 'package:test/test.dart';

/// Covers the rules of time zones: their checks, the transitions of the
/// history and of the recurring years, and their value semantics.
void main() {
  final one = UtcOffset(hours: 1);
  final two = UtcOffset(hours: 2);
  final ZoneRules berlin = TimeZone.of('Europe/Berlin').rules;

  group('ZoneTransition', () {
    test('tells its direction and shift', () {
      final spring = ZoneTransition(Instant.epoch, one, two);
      final autumn = ZoneTransition(Instant.epoch, two, one);

      expect(spring.isGap, isTrue);
      expect(spring.isOverlap, isFalse);
      expect(autumn.isOverlap, isTrue);
      expect(spring.shift, const Duration(hours: 1));
      expect(autumn.shift, const Duration(hours: -1));
      expect(spring, ZoneTransition(Instant.epoch, one, two));
      expect(spring.hashCode, ZoneTransition(Instant.epoch, one, two).hashCode);
      expect(spring == autumn, isFalse);
      expect(spring.toString(), '1970-01-01T00:00:00Z +01:00 -> +02:00');
    });
  });

  group('ZoneTransitionRule', () {
    ZoneTransitionRule rule({
      required int day,
      DayOfWeek? dayOfWeek,
      bool onOrBefore = false,
    }) => ZoneTransitionRule(
      month: Month.march,
      day: day,
      dayOfWeek: dayOfWeek,
      onOrBefore: onOrBefore,
      timeOfDay: const Duration(hours: 2),
      offsetAfter: two,
    );

    test('finds its day in a year', () {
      expect(rule(day: 14).dateIn(2026), LocalDate(2026, 3, 14));
      expect(rule(day: -1).dateIn(2026), LocalDate(2026, 3, 31));
      expect(
        rule(
          day: -1,
          dayOfWeek: DayOfWeek.sunday,
          onOrBefore: true,
        ).dateIn(2026),
        LocalDate(2026, 3, 29),
      );
      expect(
        rule(day: 8, dayOfWeek: DayOfWeek.sunday).dateIn(2026),
        LocalDate(2026, 3, 8),
      );
      expect(
        rule(
          day: 14,
          dayOfWeek: DayOfWeek.saturday,
          onOrBefore: true,
        ).dateIn(2026),
        LocalDate(2026, 3, 14),
      );
      expect(
        rule(day: 31, dayOfWeek: DayOfWeek.wednesday).dateIn(2026),
        LocalDate(2026, 4, 1),
      );
      expect(() => rule(day: 0), throwsArgumentError);
      expect(() => rule(day: 32), throwsArgumentError);
    });

    test('compares and describes itself', () {
      final ZoneTransitionRule last = rule(
        day: -1,
        dayOfWeek: DayOfWeek.sunday,
        onOrBefore: true,
      );

      expect(last.timeOfDay, const Duration(hours: 2));
      expect(
        last,
        rule(day: -1, dayOfWeek: DayOfWeek.sunday, onOrBefore: true),
      );
      expect(
        last.hashCode,
        rule(day: -1, dayOfWeek: DayOfWeek.sunday, onOrBefore: true).hashCode,
      );
      expect(last == rule(day: -1), isFalse);
      expect(last.toString(), 'march -1 sunday<= 7200s wall -> +02:00');
      expect(
        rule(day: 8, dayOfWeek: DayOfWeek.sunday).toString(),
        contains('sunday>='),
      );
      expect(rule(day: 14).toString(), 'march 14 7200s wall -> +02:00');
    });
  });

  group('RecurringZoneRule', () {
    final southern = RecurringZoneRule(
      standardOffset: UtcOffset(hours: 10),
      rules: <ZoneTransitionRule>[
        ZoneTransitionRule(
          month: Month.october,
          day: 1,
          dayOfWeek: DayOfWeek.sunday,
          timeOfDay: const Duration(hours: 2),
          definition: ZoneTimeDefinition.standard,
          offsetAfter: UtcOffset(hours: 11),
        ),
        ZoneTransitionRule(
          month: Month.april,
          day: 1,
          dayOfWeek: DayOfWeek.sunday,
          timeOfDay: const Duration(hours: 2),
          definition: ZoneTimeDefinition.standard,
          offsetAfter: UtcOffset(hours: 10),
        ),
      ],
    );

    test('lists the transitions of a year in time order', () {
      expect(southern.transitionsIn(2026), <ZoneTransition>[
        ZoneTransition(
          Instant.parse('2026-04-04T16:00:00Z'),
          UtcOffset(hours: 11),
          UtcOffset(hours: 10),
        ),
        ZoneTransition(
          Instant.parse('2026-10-03T16:00:00Z'),
          UtcOffset(hours: 10),
          UtcOffset(hours: 11),
        ),
      ]);
    });

    test('refuses an empty year and compares', () {
      expect(
        () => RecurringZoneRule(
          standardOffset: one,
          rules: const <ZoneTransitionRule>[],
        ),
        throwsArgumentError,
      );
      expect(
        southern,
        RecurringZoneRule(
          standardOffset: UtcOffset(hours: 10),
          rules: southern.rules,
        ),
      );
      expect(
        southern.hashCode,
        RecurringZoneRule(
          standardOffset: UtcOffset(hours: 10),
          rules: southern.rules,
        ).hashCode,
      );
      expect(
        southern ==
            RecurringZoneRule(
              standardOffset: UtcOffset(hours: 10),
              rules: southern.rules.reversed.toList(),
            ),
        isFalse,
      );
      expect(
        southern ==
            RecurringZoneRule(
              standardOffset: UtcOffset(hours: 10),
              rules: southern.rules.sublist(1),
            ),
        isFalse,
      );
      expect(southern.toString(), startsWith('RecurringZoneRule(+10:00'));
    });
  });

  group('ZoneRules', () {
    test('checks that its history is in order and continuous', () {
      final Instant later = Instant.epoch + const Duration(days: 1);

      expect(
        () => ZoneRules(
          initialOffset: one,
          transitions: <ZoneTransition>[
            ZoneTransition(later, one, two),
            ZoneTransition(Instant.epoch, two, one),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => ZoneRules(
          initialOffset: one,
          transitions: <ZoneTransition>[ZoneTransition(later, two, one)],
        ),
        throwsArgumentError,
      );
      expect(ZoneRules.fixed(one).isFixed, isTrue);
      expect(berlin.isFixed, isFalse);
    });

    test('finds the next and the previous transition', () {
      final summer = Instant.parse('2026-07-01T00:00:00Z');

      expect(
        berlin.nextTransition(summer)?.instant,
        Instant.parse('2026-10-25T01:00:00Z'),
      );
      expect(
        berlin.previousTransition(summer)?.instant,
        Instant.parse('2026-03-29T01:00:00Z'),
      );
      expect(
        berlin
            .previousTransition(Instant.parse('2026-03-29T01:00:00Z'))
            ?.instant,
        Instant.parse('2025-10-26T01:00:00Z'),
      );
      expect(
        berlin
            .nextTransition(Instant.parse('1890-01-01T00:00:00Z'))
            ?.offsetBefore,
        UtcOffset(minutes: 53, seconds: 28),
      );
      expect(
        berlin.previousTransition(Instant.parse('1890-01-01T00:00:00Z')),
        isNull,
      );
      expect(
        berlin
            .previousTransition(Instant.parse('1980-07-01T00:00:00Z'))
            ?.instant,
        Instant.parse('1980-04-06T01:00:00Z'),
      );
      expect(ZoneRules.fixed(one).nextTransition(summer), isNull);
      expect(ZoneRules.fixed(one).previousTransition(summer), isNull);
    });

    test('lists the transitions of a span', () {
      final List<ZoneTransition> list = berlin.transitionsBetween(
        Instant.parse('2025-01-01T00:00:00Z'),
        Instant.parse('2027-01-01T00:00:00Z'),
      );

      expect(list, hasLength(4));
      expect(list.first.instant, Instant.parse('2025-03-30T01:00:00Z'));
      expect(
        () => berlin.transitionsBetween(Instant.epoch, Instant.distantFuture),
        throwsArgumentError,
      );
      expect(
        ZoneRules.fixed(one).transitionsBetween(Instant.min, Instant.max),
        isEmpty,
      );
    });

    test('reads offsets far beyond its history', () {
      expect(
        berlin.offsetAt(Instant.parse('2900-07-01T00:00:00Z')),
        UtcOffset(hours: 2),
      );
      expect(
        berlin.infoAt(LocalDateTime.of(2900, 3, 31, 2, 30)),
        isA<RegularOffsetInfo>(),
      );
      for (var year = 2030; year < 2200; year += 1) {
        berlin.offsetAt(Instant.parse('$year-07-01T00:00:00Z'));
      }
      expect(
        berlin.offsetAt(Instant.parse('2026-01-01T00:00:00Z')),
        UtcOffset(hours: 1),
      );
    });

    test('compares and describes itself', () {
      final ZoneRules copy = TimeZone.of('Europe/Berlin').rules;

      expect(berlin, copy);
      expect(berlin.hashCode, copy.hashCode);
      expect(berlin == TimeZone.of('Europe/Paris').rules, isFalse);
      expect(ZoneRules.fixed(one) == ZoneRules.fixed(two), isFalse);
      expect(
        ZoneRules(
              initialOffset: one,
              transitions: <ZoneTransition>[
                ZoneTransition(Instant.epoch, one, two),
              ],
            ) ==
            ZoneRules(
              initialOffset: one,
              transitions: <ZoneTransition>[
                ZoneTransition(Instant.max, one, two),
              ],
            ),
        isFalse,
      );
      expect(berlin.toString(), startsWith('ZoneRules(+00:53:28'));
    });
  });

  group('offset information', () {
    test('compares and describes itself', () {
      final transition = ZoneTransition(Instant.epoch, one, two);

      expect(RegularOffsetInfo(one), RegularOffsetInfo(one));
      expect(RegularOffsetInfo(one).hashCode, one.hashCode);
      expect(RegularOffsetInfo(one).toString(), 'Regular(+01:00)');
      expect(GapOffsetInfo(transition), GapOffsetInfo(transition));
      expect(GapOffsetInfo(transition).hashCode, transition.hashCode);
      expect(GapOffsetInfo(transition).toString(), startsWith('Gap('));
      expect(OverlapOffsetInfo(transition), OverlapOffsetInfo(transition));
      expect(OverlapOffsetInfo(transition).hashCode, transition.hashCode);
      expect(OverlapOffsetInfo(transition).toString(), startsWith('Overlap('));
    });
  });
}
