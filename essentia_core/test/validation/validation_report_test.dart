/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';
import 'package:test/test.dart';

import 'plain_violation.dart';

/// Covers how a [ValidationReport] classifies and renders what it holds.
void main() {
  group('classification', () {
    test('an empty report is valid and holds nothing', () {
      final report = ValidationReport('configuration', const <Violation>[]);

      expect(report.isValid, isTrue);
      expect(report.violations, isEmpty);
      expect(report.errors, isEmpty);
      expect(report.warnings, isEmpty);
    });

    test('errors and warnings keep the order they were reported in', () {
      final report = ValidationReport('configuration', <Violation>[
        PlainViolation.error('b', 'second'),
        PlainViolation.warning('w1', 'first warning'),
        PlainViolation.error('a', 'third'),
        PlainViolation.warning('w2', 'second warning'),
      ]);

      expect(
        report.errors.map((violation) => violation.message).toList(),
        <String>['second', 'third'],
      );
      expect(
        report.warnings.map((violation) => violation.message).toList(),
        <String>['first warning', 'second warning'],
      );
    });

    test('the report keeps a copy that cannot be changed', () {
      final source = <Violation>[PlainViolation.error('a', 'wrong')];
      final report = ValidationReport('configuration', source);

      source.add(PlainViolation.error('b', 'later'));

      expect(report.violations, hasLength(1));
      expect(
        () => report.violations.add(PlainViolation.error('c', 'more')),
        throwsUnsupportedError,
      );
    });
  });

  group('rendering', () {
    test('an empty report renders as nothing', () {
      expect(
        ValidationReport('configuration', const <Violation>[]).render(),
        '',
      );
    });

    test('a single error is one problem', () {
      final report = ValidationReport('configuration', <Violation>[
        PlainViolation.error('sinks', 'must not be empty'),
      ]);

      expect(
        report.render(),
        'Invalid configuration (1 problem):\n'
        '\n'
        '  sinks  must not be empty',
      );
    });

    test('several errors are plural and aligned on the longest path', () {
      final report = ValidationReport('configuration', <Violation>[
        PlainViolation.error('a', 'first'),
        PlainViolation.error('abcd', 'second'),
      ]);

      expect(
        report.render(),
        'Invalid configuration (2 problems):\n'
        '\n'
        '  a     first\n'
        '  abcd  second',
      );
    });

    test('errors come first even when a warning was reported earlier', () {
      final report = ValidationReport('workspace', <Violation>[
        PlainViolation.warning('level', 'is expensive'),
        PlainViolation.error('name', 'must not be blank'),
      ]);

      expect(
        report.render(),
        'Invalid workspace (1 problem):\n'
        '\n'
        '  name  must not be blank\n'
        '\n'
        '1 warning:\n'
        '\n'
        '  level  is expensive',
      );
    });

    test('warnings alone render without the error headline', () {
      final report = ValidationReport('configuration', <Violation>[
        PlainViolation.warning('level', 'is expensive'),
        PlainViolation.warning('format', 'is deprecated'),
      ]);

      expect(
        report.render(),
        '2 warnings:\n'
        '\n'
        '  level   is expensive\n'
        '  format  is deprecated',
      );
    });

    test('errors and warnings are aligned independently of each other', () {
      final report = ValidationReport('configuration', <Violation>[
        PlainViolation.error('a', 'short'),
        PlainViolation.warning('a.much.longer.path', 'long'),
      ]);

      expect(
        report.render(),
        'Invalid configuration (1 problem):\n'
        '\n'
        '  a  short\n'
        '\n'
        '1 warning:\n'
        '\n'
        '  a.much.longer.path  long',
      );
    });

    test('a violation of the whole object renders with an empty path', () {
      final report = ValidationReport('configuration', <Violation>[
        PlainViolation.error('', 'makes no sense'),
        PlainViolation.error('ab', 'is wrong'),
      ]);

      expect(
        report.render(),
        'Invalid configuration (2 problems):\n'
        '\n'
        '      makes no sense\n'
        '  ab  is wrong',
      );
    });

    test('a path of exactly 28 characters still sets the column', () {
      final String path = 'p' * 28;
      final report = ValidationReport('configuration', <Violation>[
        PlainViolation.error('x', 'short'),
        PlainViolation.error(path, 'long'),
      ]);

      expect(report.render().split('\n').skip(2).toList(), <String>[
        '  x${' ' * 29}short',
        '  $path  long',
      ]);
    });

    test('the column stops growing at 28 characters', () {
      final String path = 'p' * 40;
      final report = ValidationReport('configuration', <Violation>[
        PlainViolation.error('x', 'short'),
        PlainViolation.error(path, 'long'),
      ]);

      final List<String> lines = report.render().split('\n').skip(2).toList();

      expect(lines.first, '  x${' ' * 29}short');
      expect(lines.last, '  $path long');
    });

    test('a path as wide as the column keeps one space before its message', () {
      final String path = 'p' * 30;
      final report = ValidationReport('configuration', <Violation>[
        PlainViolation.error('x', 'short'),
        PlainViolation.error(path, 'long'),
      ]);

      expect(report.render().split('\n').skip(2).toList(), <String>[
        '  x${' ' * 29}short',
        '  $path long',
      ]);
    });

    test('the footer is rendered below the violations', () {
      final report = ValidationReport('program parameters', <Violation>[
        PlainViolation.error('--port', 'must be a number'),
      ], footer: 'Usage: app [options]');

      expect(
        report.render(),
        'Invalid program parameters (1 problem):\n'
        '\n'
        '  --port  must be a number\n'
        '\n'
        'Usage: app [options]',
      );
    });

    test('a footer alone is the whole rendering of an empty report', () {
      final report = ValidationReport(
        'program parameters',
        const <Violation>[],
        footer: 'Usage: app [options]',
      );

      expect(report.render(), 'Usage: app [options]');
    });

    test('the rendering has no trailing newline', () {
      final report = ValidationReport('configuration', <Violation>[
        PlainViolation.error('a', 'wrong'),
        PlainViolation.warning('b', 'odd'),
      ]);

      expect(report.render(), isNot(endsWith('\n')));
    });

    test('the string form of a report is its rendering', () {
      final report = ValidationReport('configuration', <Violation>[
        PlainViolation.error('a', 'wrong'),
      ]);

      expect(report.toString(), report.render());
    });
  });
}
