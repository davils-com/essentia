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

/// Covers what a [ValidationException] carries and how it reads.
void main() {
  test('the exception carries the whole report, warnings included', () {
    final report = ValidationReport('configuration', <Violation>[
      PlainViolation.error('a', 'wrong'),
      PlainViolation.error('b', 'also wrong'),
      PlainViolation.warning('c', 'odd'),
    ]);

    final failure = ValidationException(report);

    expect(failure.report, same(report));
    expect(failure.report.errors, hasLength(2));
    expect(failure.report.warnings, hasLength(1));
  });

  test('the message is the rendered report', () {
    final report = ValidationReport('configuration', <Violation>[
      PlainViolation.error('sinks', 'must not be empty'),
      PlainViolation.warning('level', 'is expensive'),
    ]);

    final failure = ValidationException(report);

    expect(
      failure.message,
      'Invalid configuration (1 problem):\n'
      '\n'
      '  sinks  must not be empty\n'
      '\n'
      '1 warning:\n'
      '\n'
      '  level  is expensive',
    );
  });

  test('printing the exception prints the report', () {
    final report = ValidationReport('workspace', <Violation>[
      PlainViolation.error('name', 'must not be blank'),
    ], footer: 'See the manual.');

    final failure = ValidationException(report);

    expect(failure.toString(), report.render());
    expect(failure.toString(), endsWith('See the manual.'));
  });

  test('the exception is an Exception rather than an Error', () {
    final failure = ValidationException(
      ValidationReport('configuration', <Violation>[
        PlainViolation.error('a', 'wrong'),
      ]),
    );

    expect(failure, isA<Exception>());
    expect(failure, isNot(isA<Error>()));
  });
}
