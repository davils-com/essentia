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

import 'ageing_parameters.dart';
import 'failure_of.dart';
import 'validated_parameters.dart';

/// No environment at all.
const _nothing = <String, String>{};

/// Tests what loads with a warning rather than failing.
void main() {
  test('a deprecated parameter that is not given says nothing', () {
    final parameters = AgeingParameters()
      ..load(<String>['--port=8080'], environment: _nothing);

    expect(parameters.warnings, isEmpty);
  });

  test('a deprecated parameter that is given still loads with its value', () {
    final parameters = AgeingParameters()
      ..load(<String>['--port=8080', '--old-dir=/srv'], environment: _nothing);

    expect(parameters.oldDir.value, '/srv');
    expect(parameters.isLoaded, isTrue);
  });

  test('a deprecated parameter that is given warns with its advice', () {
    final parameters = AgeingParameters()
      ..load(<String>['--port=8080', '--old-dir=/srv'], environment: _nothing);

    final Violation warning = parameters.warnings.single;
    expect(warning, isA<DeprecatedParameter>());
    expect(warning.severity, Severity.warning);
    expect(warning.code, ParameterViolationCodes.deprecated);
    expect(warning.path.toString(), '--old-dir');
    expect(warning.message, 'is deprecated: use --data-dir instead');
  });

  test('a deprecation without advice says only that', () {
    final parameters = AgeingParameters()
      ..load(<String>['--port=8080', '--legacy'], environment: _nothing);

    expect(parameters.warnings.single.message, 'is deprecated');
  });

  test('a deprecated parameter fed from the environment warns as well', () {
    final parameters = AgeingParameters()
      ..load(
        <String>['--port=8080'],
        environment: <String, String>{'APP_OLD_DIR': '/srv'},
      );

    expect(parameters.warnings, hasLength(1));
  });

  test('warnings appear in their own block of a failed load', () {
    final ParameterException failure = failureOf(
      () => AgeingParameters().load(<String>[
        '--old-dir=/srv',
      ], environment: _nothing),
    );

    expect(failure.report.errors, hasLength(1));
    expect(failure.report.warnings, hasLength(1));
    final String message = failure.message;
    expect(message, contains('Invalid program parameters (1 problem):'));
    expect(message, contains('1 warning:'));
    expect(message, contains('is deprecated: use --data-dir instead'));
  });

  test('the usage listing marks a deprecated parameter', () {
    expect(AgeingParameters().usage(), contains('deprecated'));
  });

  test('a rule that only warns leaves the value usable', () {
    final parameters = ValidatedParameters()
      ..load(<String>['--threads=512'], environment: _nothing);

    expect(parameters.threads.value, 512);
    expect(parameters.warnings.single.message, contains('unusually high'));
  });

  test('a rule that warns and a rule that fails are both reported', () {
    final ParameterException failure = failureOf(
      () => ValidatedParameters().load(<String>[
        '--threads=-1',
      ], environment: _nothing),
    );

    final Violation warning = failure.report.warnings.single;
    expect(warning, isA<ValidationFailure>());
    expect(warning.severity, Severity.warning);
    expect(failure.report.errors, hasLength(1));
  });
}
