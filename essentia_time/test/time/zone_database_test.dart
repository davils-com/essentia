/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_time/essentia_time.dart';
import 'package:essentia_time/src/internal/zone_data_codec.dart';
import 'package:test/test.dart';

/// The transitions of hard zones in one year, as the reference compiler
/// of the time zone database writes them: zone, year, and each transition
/// as its moment and the offsets before and after in seconds.
const _known = <(String, int, List<(String, int, int)>)>[
  (
    'Europe/Berlin',
    2026,
    <(String, int, int)>[
      ('2026-03-29T01:00:00Z', 3600, 7200),
      ('2026-10-25T01:00:00Z', 7200, 3600),
    ],
  ),
  (
    'America/New_York',
    2026,
    <(String, int, int)>[
      ('2026-03-08T07:00:00Z', -18000, -14400),
      ('2026-11-01T06:00:00Z', -14400, -18000),
    ],
  ),
  (
    'Australia/Lord_Howe',
    2026,
    <(String, int, int)>[
      ('2026-04-04T15:00:00Z', 39600, 37800),
      ('2026-10-03T15:30:00Z', 37800, 39600),
    ],
  ),
  (
    'Pacific/Apia',
    2011,
    <(String, int, int)>[
      ('2011-04-02T14:00:00Z', -36000, -39600),
      ('2011-09-24T14:00:00Z', -39600, -36000),
      ('2011-12-30T10:00:00Z', -36000, 50400),
    ],
  ),
  (
    'Pacific/Kiritimati',
    1994,
    <(String, int, int)>[('1994-12-31T10:00:00Z', -36000, 50400)],
  ),
  (
    'America/Sao_Paulo',
    2018,
    <(String, int, int)>[
      ('2018-02-18T02:00:00Z', -7200, -10800),
      ('2018-11-04T03:00:00Z', -10800, -7200),
    ],
  ),
  (
    'Europe/Moscow',
    2011,
    <(String, int, int)>[('2011-03-26T23:00:00Z', 10800, 14400)],
  ),
  (
    'Europe/Moscow',
    2014,
    <(String, int, int)>[('2014-10-25T22:00:00Z', 14400, 10800)],
  ),
  (
    'Europe/Dublin',
    2026,
    <(String, int, int)>[
      ('2026-03-29T01:00:00Z', 0, 3600),
      ('2026-10-25T01:00:00Z', 3600, 0),
    ],
  ),
  (
    'Africa/Casablanca',
    2026,
    <(String, int, int)>[
      ('2026-02-15T02:00:00Z', 3600, 0),
      ('2026-03-22T02:00:00Z', 0, 3600),
      ('2026-09-20T01:00:00Z', 3600, 0),
    ],
  ),
  (
    'America/Nuuk',
    2023,
    <(String, int, int)>[('2023-03-26T01:00:00Z', -10800, -7200)],
  ),
  (
    'Antarctica/Troll',
    2026,
    <(String, int, int)>[
      ('2026-03-29T01:00:00Z', 0, 7200),
      ('2026-10-25T01:00:00Z', 7200, 0),
    ],
  ),
  (
    'America/St_Johns',
    2026,
    <(String, int, int)>[
      ('2026-03-08T05:30:00Z', -12600, -9000),
      ('2026-11-01T04:30:00Z', -9000, -12600),
    ],
  ),
  (
    'Asia/Hebron',
    2026,
    <(String, int, int)>[
      ('2026-03-28T00:00:00Z', 7200, 10800),
      ('2026-10-23T23:00:00Z', 10800, 7200),
    ],
  ),
  (
    'Asia/Kathmandu',
    1986,
    <(String, int, int)>[('1985-12-31T18:30:00Z', 19800, 20700)],
  ),
  (
    'Australia/Sydney',
    2026,
    <(String, int, int)>[
      ('2026-04-04T16:00:00Z', 39600, 36000),
      ('2026-10-03T16:00:00Z', 36000, 39600),
    ],
  ),
  (
    'America/Santiago',
    2026,
    <(String, int, int)>[
      ('2026-04-05T03:00:00Z', -10800, -14400),
      ('2026-09-06T04:00:00Z', -14400, -10800),
    ],
  ),
];

/// Checks the built-in database against transitions the reference
/// compiler writes, and every zone for consistency.
void main() {
  for (final (String id, int year, List<(String, int, int)> expected)
      in _known) {
    test('$id shifts its clocks in $year as the reference does', () {
      final ZoneRules rules = TimeZone.of(id).rules;
      final List<ZoneTransition> actual = rules.transitionsBetween(
        Instant.parse('${year - 1}-12-31T00:00:00Z'),
        Instant.parse('${year + 1}-01-01T00:00:00Z'),
      );

      expect(actual, <ZoneTransition>[
        for (final (String at, int before, int after) in expected)
          ZoneTransition(
            Instant.parse(at),
            UtcOffset.fromTotalSeconds(before),
            UtcOffset.fromTotalSeconds(after),
          ),
      ]);
      for (final transition in actual) {
        final Instant at = transition.instant;
        expect(
          rules.offsetAt(at - const Duration(seconds: 1)),
          transition.offsetBefore,
        );
        expect(rules.offsetAt(at), transition.offsetAfter);
      }
    });
  }

  test('every zone converts around each of its transitions consistently', () {
    for (final String id in TimeZone.availableZoneIds) {
      final TimeZone zone = TimeZone.of(id);
      for (final ZoneTransition transition in zone.rules.transitionsBetween(
        Instant.parse('1970-01-01T00:00:00Z'),
        Instant.parse('2040-01-01T00:00:00Z'),
      )) {
        final Instant before = transition.instant - const Duration(hours: 3);
        final Instant after = transition.instant + const Duration(hours: 3);
        for (final instant in <Instant>[before, after]) {
          final LocalDateTime local = zone.toLocalDateTime(instant);
          final ZoneOffsetInfo info = zone.offsetInfo(local);
          if (info is RegularOffsetInfo) {
            expect(zone.toInstant(local), instant, reason: '$id $instant');
          }
        }
      }
    }
  });

  test('the recurring rule continues the history seamlessly', () {
    for (final id in <String>[
      'Europe/Berlin',
      'America/New_York',
      'Australia/Sydney',
      'America/Santiago',
      'Pacific/Auckland',
    ]) {
      final ZoneRules rules = TimeZone.of(id).rules;
      for (var year = 2030; year <= 2100; year += 10) {
        expect(
          rules.transitionsBetween(
            Instant.parse('$year-01-01T00:00:00Z'),
            Instant.parse('${year + 1}-01-01T00:00:00Z'),
          ),
          hasLength(2),
          reason: '$id $year',
        );
      }
    }
  });

  test('the compact format writes and reads every zone unchanged', () {
    for (final String id in TimeZone.availableZoneIds) {
      final ZoneRules rules = TimeZone.of(id).rules;
      expect(decodeZone(encodeZone(rules)), rules, reason: id);
    }
  });

  test('the compact format refuses what it did not write', () {
    expect(() => decodeZone(''), throwsFormatException);
    expect(() => decodeZone('B'), throwsFormatException);
    expect(() => decodeZone(r'B$'), throwsFormatException);
  });
}
