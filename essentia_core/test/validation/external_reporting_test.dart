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
