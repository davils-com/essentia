/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/icalendar.dart';
import 'package:test/test.dart';

/// Covers the content lines of iCalendar: folding, escaping, reading and
/// writing.
void main() {
  group('text', () {
    test('folds at 75 octets without cutting a character', () {
      final line = 'DESCRIPTION:${'ä' * 60}';
      final String folded = foldIcsLine(line);
      final List<String> parts = folded.split('\r\n');

      expect(parts.length, 2);
      expect(parts.first.codeUnits.length, lessThanOrEqualTo(75));
      expect(unfoldIcs(folded), <String>[line]);
      expect(foldIcsLine('SUMMARY:short'), 'SUMMARY:short');
      expect(foldIcsLine('X:${'🙂' * 30}').split('\r\n').length, 2);
    });

    test('unfolds every kind of line break', () {
      expect(unfoldIcs('A:1\r\n B\nC:2\r\tD\r\n\r\n'), <String>[
        'A:1B',
        'C:2D',
      ]);
    });

    test('escapes and unescapes text', () {
      const text = 'a\\b;c,d\ne';
      final String escaped = escapeIcsText(text);

      expect(escaped, r'a\\b\;c\,d\ne');
      expect(unescapeIcsText(escaped), text);
      expect(unescapeIcsText(r'line\Nnext\'), 'line\nnext\\');
      expect(splitIcsList(r'a,b\,c,,d'), <String>['a', r'b\,c', '', 'd']);
      expect(splitIcsList(r'end\'), <String>[r'end\']);
    });
  });

  group('content lines', () {
    test('reads parameters, quoted ones and lists', () {
      final IcsProperty? property = parseIcsContentLine(
        <String>[
          'ATTENDEE;CN="Ada; Lovelace";ROLE=CHAIR;',
          'MEMBER="mailto:a@x.org","mailto:b@x.org";',
          'rsvp=TRUE:mailto:ada@example.com',
        ].join(),
      );

      expect(property?.name, 'ATTENDEE');
      expect(property?.value, 'mailto:ada@example.com');
      expect(property?.parameter('CN'), 'Ada; Lovelace');
      expect(property?.parameter('rsvp'), 'TRUE');
      expect(property?.parameters['MEMBER'], <String>[
        'mailto:a@x.org',
        'mailto:b@x.org',
      ]);
      expect(property?.parameter('MISSING'), isNull);
      expect(parseIcsContentLine('X-EMPTY;A=:value')?.parameters['A'], isEmpty);
    });

    test('refuses lines that are none', () {
      expect(parseIcsContentLine(':value'), isNull);
      expect(parseIcsContentLine('NAME value'), isNull);
      expect(parseIcsContentLine('NAME;PARAM:value'), isNull);
      expect(parseIcsContentLine('NAME;P A=x:value'), isNull);
      expect(parseIcsContentLine('NAME;P="open:value'), isNull);
      expect(parseIcsContentLine('NAME;P="a"b:value'), isNull);
      expect(parseIcsContentLine('NAME;P=a'), isNull);
    });

    test('writes what it reads', () {
      final property = IcsProperty(
        'attendee',
        'mailto:ada@example.com',
        parameters: const <String, List<String>>{
          'cn': <String>['Ada; Lovelace'],
          'ROLE': <String>['CHAIR'],
        },
      );

      expect(
        property.toString(),
        'ATTENDEE;CN="Ada; Lovelace";ROLE=CHAIR:mailto:ada@example.com',
      );
      expect(parseIcsContentLine(property.toString()), property);
      expect(
        property.hashCode,
        parseIcsContentLine(property.toString()).hashCode,
      );
      expect(property == IcsProperty('ATTENDEE', 'x'), isFalse);
      expect(
        property ==
            IcsProperty(
              'ATTENDEE',
              'mailto:ada@example.com',
              parameters: const <String, List<String>>{
                'CN': <String>['Ada'],
                'ROLE': <String>['CHAIR'],
              },
            ),
        isFalse,
      );
    });
  });

  group('components', () {
    test('nest, look up and compare', () {
      final problems = <String>[];
      final List<IcsComponent> roots = readIcs(
        'BEGIN:VCALENDAR\r\nVERSION:2.0\r\nBEGIN:VEVENT\r\nUID:1\r\n'
        'CATEGORIES:A\r\nCATEGORIES:B\r\nEND:VEVENT\r\nEND:VCALENDAR\r\n',
        problems,
      );
      final IcsComponent calendar = roots.single;

      expect(problems, isEmpty);
      expect(calendar.name, 'VCALENDAR');
      expect(calendar.property('version')?.value, '2.0');
      expect(calendar.property('PRODID'), isNull);
      expect(
        calendar.children('vevent').single.all('CATEGORIES'),
        hasLength(2),
      );
      expect(
        calendar.toString(),
        'IcsComponent(VCALENDAR, 1 properties, 1 components)',
      );
      expect(readIcs(writeIcs(calendar), <String>[]).single, calendar);
      expect(
        calendar.hashCode,
        readIcs(writeIcs(calendar), <String>[]).single.hashCode,
      );
      expect(calendar == IcsComponent('VCALENDAR'), isFalse);
      expect(
        IcsComponent('A', properties: <IcsProperty>[IcsProperty('X', '1')]) ==
            IcsComponent('A', properties: <IcsProperty>[IcsProperty('X', '2')]),
        isFalse,
      );
    });

    test('report what is broken and read on', () {
      final problems = <String>[];
      final List<IcsComponent> roots = readIcs(
        'STRAY:1\nBEGIN:VCALENDAR\nnot a line\nEND:VEVENT\nBEGIN:VEVENT\nUID:1',
        problems,
      );

      expect(problems, <String>[
        'line 1: STRAY outside a component',
        'line 3: not a content line',
        'line 4: END:VEVENT closes nothing',
        'end of text: VEVENT is not closed',
        'end of text: VCALENDAR is not closed',
      ]);
      expect(
        roots.single.children('VEVENT').single.property('UID')?.value,
        '1',
      );
    });
  });
}
