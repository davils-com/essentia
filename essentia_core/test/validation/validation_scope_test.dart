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

import 'scope_probe_builder.dart';

/// A code of the test's own, distinct from every default.
const _ownCode = ViolationCode('test.custom');

/// Validates a probe running [rules] and returns what it reported.
ValidationReport _report(void Function(ValidationScope it) rules) =>
    ScopeProbeBuilder(rules).validate();

/// The rendered paths of everything [report] holds, in order.
List<String> _paths(ValidationReport report) =>
    report.violations.map((violation) => violation.path.toString()).toList();

/// Covers the checks of a validation scope and the report they build.
void main() {
  test('failing without a property reports at the root', () {
    final ValidationReport result = _report(
      (it) => it.fail('must not be empty'),
    );

    final Violation violation = result.violations.single;
    expect(violation.path, ViolationPath.root);
    expect(violation.message, 'must not be empty');
    expect(violation.severity, Severity.error);
  });

  test('failing with a property reports at that property', () {
    final ValidationReport result = _report(
      (it) => it.fail('must not be empty', property: 'sinks'),
    );

    expect(result.violations.single.path.toString(), 'sinks');
  });

  test('every report is kept, not just the first', () {
    final ValidationReport result = _report((it) {
      it
        ..fail('must not be empty', property: 'sinks')
        ..fail('is not a known level', property: 'level')
        ..fail('the configuration as a whole makes no sense');
    });

    expect(result.violations, hasLength(3));
    expect(_paths(result), <String>['sinks', 'level', '']);
  });

  test('a violation carries the default code unless one is given', () {
    final Violation defaulted = _report((it) => it.fail('wrong'))
        .violations
        .single;
    final Violation explicit = _report((it) => it.fail('wrong', code: _ownCode))
        .violations
        .single;

    expect(defaulted.code, ViolationCode.invalid);
    expect(explicit.code, _ownCode);
  });

  test('a warning does not invalidate the report', () {
    final ValidationReport result = _report(
      (it) => it.warn('trace is expensive in production', property: 'level'),
    );

    expect(result.isValid, isTrue);
    expect(result.warnings, hasLength(1));
    expect(result.errors, isEmpty);
  });

  test('one error among warnings invalidates the report', () {
    final ValidationReport result = _report((it) {
      it
        ..warn('trace is expensive in production', property: 'level')
        ..fail('must not be empty', property: 'sinks');
    });

    expect(result.isValid, isFalse);
    expect(result.errors, hasLength(1));
    expect(result.warnings, hasLength(1));
  });

  test('descending prefixes everything reported inside', () {
    final ValidationReport result = _report((it) {
      it.at('sinks', (it) {
        it
          ..fail('is not a known level', property: 'level')
          ..fail('must be configured');
      });
    });

    expect(_paths(result), <String>['sinks.level', 'sinks']);
  });

  test('descending nests to any depth', () {
    final ValidationReport result = _report((it) {
      it.at('sinks', (it) {
        it.at('level', (it) => it.fail('is not a known level'));
      });
    });

    expect(result.violations.single.path.toString(), 'sinks.level');
  });

  test('validating each element reports under its index', () {
    final ValidationReport result = _report((it) {
      it.each('sinks', <String>['a', 'b', 'c'], (it, item) {
        if (item != 'b') {
          it.fail('unexpected $item', property: 'level');
        }
      });
    });

    expect(_paths(result), <String>['sinks[0].level', 'sinks[2].level']);
  });

  test('included violations are re-reported under the path they were '
      'included at', () {
    final ValidationReport inner = _report(
      (it) => it.fail('is not a known level', property: 'level'),
    );
    final ValidationReport outer = _report(
      (it) => it.include(inner.violations, ViolationPath.of('sinks').index(4)),
    );

    expect(outer.violations.single.path.toString(), 'sinks[4].level');
  });

  test('including preserves the code and the severity', () {
    final ValidationReport inner = _report(
      (it) => it.warn('is unusual', property: 'level', code: _ownCode),
    );
    final ValidationReport outer = _report(
      (it) => it.include(inner.violations),
    );

    final Violation violation = outer.violations.single;
    expect(violation.code, _ownCode);
    expect(violation.severity, Severity.warning);
  });

  test('including the root path leaves every path as it was', () {
    final ValidationReport inner = _report(
      (it) => it.fail('is not a known level', property: 'level'),
    );
    final ValidationReport outer = _report((it) {
      it.at('sinks', (it) => it.include(inner.violations));
    });

    expect(outer.violations.single.path.toString(), 'sinks.level');
    expect(outer.violations.single.message, 'is not a known level');
  });
}
