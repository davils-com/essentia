/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

@TestOn('vm')
library;

import 'dart:io';

import 'package:essentia/essentia.dart' hide Platform;
import 'package:test/test.dart';

import '../../tool/generate_tzdata.dart';
import '../../tool/generate_tzdata.dart' as generator show main;

/// A small source in the format of the database: rules with every kind of
/// day and time, a zone with continuation lines and links.
const _source = '''
# Rules of a made-up country.
Rule	Demo	1990	1995	-	Mar	lastSun	1:00u	1:00	S
Rule	Demo	1990	1995	-	Sep	Sun>=24	1:00u	0	-
Rule	Demo	1996	max	-	Mar	lastSun	1:00u	1:00	S
Rule	Demo	1996	max	-	Oct	lastSun	1:00u	0	-
Rule	Odd	1980	only	-	Apr	Sat<=7	24:00	1:00	S
Rule	Odd	1980	only	-	Oct	15	2:00s	0	-

Zone	Demo/City	0:53:28 -	LMT	1893 Apr
			1:00	Odd	CE%sT	1985
			1:00	-	CET	1990
			1:00	Demo	CE%sT
Zone	Demo/Fixed	2:00	1:00	+03	# fixed saving
Link	Demo/City	Demo/Alias
Link	Demo/Alias	Demo/Chain
''';

/// Covers the compiler of the time zone database.
void main() {
  group('reading', () {
    test('reads times on every clock', () {
      expect(ZicTime.parse('2:00').seconds, 7200);
      expect(ZicTime.parse('2:00').definition, ZoneTimeDefinition.wall);
      expect(ZicTime.parse('1:00u').definition, ZoneTimeDefinition.utc);
      expect(ZicTime.parse('1:00g').definition, ZoneTimeDefinition.utc);
      expect(ZicTime.parse('2:00s').definition, ZoneTimeDefinition.standard);
      expect(ZicTime.parse('24:00').seconds, 86400);
      expect(ZicTime.parse('-0:25:21').seconds, -1521);
      expect(ZicTime.parse('-').seconds, 0);
      expect(ZicTime.parse('1').seconds, 3600);
      expect(() => ZicTime.parse('noon'), throwsFormatException);
    });

    test('converts a time to UTC on its clock', () {
      expect(ZicTime.toUtc(7200, ZoneTimeDefinition.utc, 3600, 3600), 7200);
      expect(
        ZicTime.toUtc(7200, ZoneTimeDefinition.standard, 3600, 3600),
        3600,
      );
      expect(ZicTime.toUtc(7200, ZoneTimeDefinition.wall, 3600, 3600), 0);
    });

    test('reads months and days', () {
      expect(ZicRule.parseMonth('Mar'), Month.march);
      expect(ZicRule.parseMonth('october'), Month.october);
      expect(() => ZicRule.parseMonth('Ma'), throwsFormatException);
      expect(ZicRule.parseDay('14'), (14, null, false));
      expect(ZicRule.parseDay('lastSun'), (-1, DayOfWeek.sunday, true));
      expect(ZicRule.parseDay('Sun>=8'), (8, DayOfWeek.sunday, false));
      expect(ZicRule.parseDay('Sat<=30'), (30, DayOfWeek.saturday, true));
      expect(() => ZicRule.parseDay('lastXyz'), throwsFormatException);
    });

    test('reads rules with only, max and min', () {
      final rule = ZicRule.parse(<String>[
        'min',
        'only',
        '-',
        'Apr',
        'Sun>=1',
        '2:00',
        '1:00',
        'D',
      ]);

      expect(rule.from, ZicSource.firstYear);
      expect(rule.to, ZicSource.firstYear);
      expect(rule.covers(ZicSource.firstYear), isTrue);
      expect(rule.isMax, isFalse);
      final forever = ZicRule.parse(<String>[
        '2000',
        'max',
        '-',
        'Oct',
        'lastSun',
        '1:00u',
        '0',
        '-',
      ]);
      expect(forever.isMax, isTrue);
      expect(forever.covers(2500), isTrue);
      expect(forever.localSecondsIn(2026), 1792890000);
    });

    test('reads zone lines of fixed and named saving', () {
      final fixed = ZicZoneLine.parse(<String>['2:00', '1:00', '+03']);
      final named = ZicZoneLine.parse(<String>[
        '1:00',
        'EU',
        'CE%sT',
        '1996',
        'Mar',
        'lastSun',
        '1:00u',
      ]);

      expect(fixed.save, 3600);
      expect(fixed.rules, isNull);
      expect(fixed.untilYear, isNull);
      expect(named.rules, 'EU');
      expect(named.untilYear, 1996);
      expect(named.untilUtc(3600), 828234000);
    });

    test('refuses lines it cannot read', () {
      expect(
        () => ZicSource.parse(<String>['\tcontinuation without zone']),
        throwsFormatException,
      );
      expect(
        () => ZicSource.parse(<String>['Leap 2016 Dec 31 23:59:60 + S']),
        throwsFormatException,
      );
    });
  });

  group('compiling', () {
    final source = ZicSource.parse(<String>[_source]);

    test('follows links, also to links', () {
      expect(source.canonical('Demo/Chain'), 'Demo/City');
      expect(source.canonical('Demo/City'), 'Demo/City');
      expect(() => source.canonical('Demo/Nothing'), throwsStateError);
      expect(source.lastYear, 2040);
    });

    test('compiles history, fixed lines and the recurring rule', () {
      final ZoneRules rules = source.compile('Demo/City');

      expect(rules.initialOffset, UtcOffset(minutes: 53, seconds: 28));
      expect(rules.recurring, isNotNull);
      expect(
        rules.offsetAt(Instant.parse('1980-06-01T00:00:00Z')),
        UtcOffset(hours: 2),
      );
      expect(
        rules.offsetAt(Instant.parse('1988-06-01T00:00:00Z')),
        UtcOffset(hours: 1),
      );
      expect(
        rules.offsetAt(Instant.parse('1992-07-01T00:00:00Z')),
        UtcOffset(hours: 2),
      );
      expect(
        rules.offsetAt(Instant.parse('1992-10-01T00:00:00Z')),
        UtcOffset(hours: 1),
      );
      expect(
        rules.offsetAt(Instant.parse('2300-07-01T00:00:00Z')),
        UtcOffset(hours: 2),
      );
      expect(
        rules.transitions.last.instant.isBefore(
          Instant.parse('2000-01-01T00:00:00Z'),
        ),
        isTrue,
      );
      expect(source.compile('Demo/Fixed').initialOffset, UtcOffset(hours: 3));
    });

    test('renders sorted tables and resolves links', () {
      final String dart = render('test', source);

      expect(dart, contains("const tzdataVersion = 'test';"));
      expect(dart, contains("'Demo/Alias',"));
      expect(dart, contains("'Demo/Chain',"));
      expect(
        dart.indexOf("'Demo/City'"),
        lessThan(dart.indexOf("'Demo/Fixed'")),
      );
    });

    test('finds the built-in database current', () async {
      expect(File(output).existsSync(), isTrue);
      await generator.main(<String>['--check']);
      expect(exitCode, 0);
    });
  });
}
