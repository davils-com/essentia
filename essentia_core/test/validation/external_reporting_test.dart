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

import 'decoding_failure.dart';

/// Covers the shapes a library outside Essentia reports through:
/// `Violation.of`, `ValidationReport.of` and a subclass of
/// [ValidationException].
void main() {
  test('a violation is an error unless told otherwise', () {
    final violation = Violation.of(
      ViolationPath.of('name'),
      ViolationCode.required,
      'is required but was missing',
    );

    expect(violation.path.toString(), 'name');
    expect(violation.code, ViolationCode.required);
    expect(violation.severity, Severity.error);
    expect(violation.message, 'is required but was missing');
  });

  test('a violation carries the severity it is given', () {
    const violation = Violation.of(
      ViolationPath.root,
      ViolationCode.deprecated,
      'is deprecated',
      severity: Severity.warning,
    );

    expect(violation.severity, Severity.warning);
  });

  test('a report made from outside renders like any other', () {
    final report = ValidationReport.of('workspace', <Violation>[
      Violation.of(
        ViolationPath.of('users').index(2).name('name'),
        ViolationCode.required,
        'is required but was missing',
      ),
      Violation.of(
        ViolationPath.of('tags'),
        ViolationCode.invalid,
        'should not be empty',
        severity: Severity.warning,
      ),
    ]);

    expect(report.isValid, isFalse);
    expect(
      report.render(),
      'Invalid workspace (1 problem):\n'
      '\n'
      '  users[2].name  is required but was missing\n'
      '\n'
      '1 warning:\n'
      '\n'
      '  tags  should not be empty',
    );
  });

  test('a report keeps its own copy of the violations', () {
    final violations = <Violation>[
      const Violation.of(ViolationPath.root, ViolationCode.invalid, 'is wrong'),
    ];

    final report = ValidationReport.of('workspace', violations);
    violations.clear();

    expect(report.violations, hasLength(1));
  });

  test('a subclass of the exception is caught as one', () {
    final report = ValidationReport.of('workspace', const <Violation>[
      Violation.of(ViolationPath.root, ViolationCode.invalid, 'is wrong'),
    ]);

    void fail() => throw DecodingFailure(report);

    expect(
      fail,
      throwsA(
        isA<ValidationException>().having(
          (failure) => failure.report,
          'report',
          same(report),
        ),
      ),
    );
  });
}
