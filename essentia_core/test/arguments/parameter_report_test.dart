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

import 'empty_parameters.dart';
import 'failure_of.dart';
import 'reported_parameters.dart';
import 'secret_parameters.dart';

/// What a masked value is rendered as.
const _mask = '****';

/// A secret that must never be rendered.
const _secret = 'hunter2';

/// No environment at all.
const _nothing = <String, String>{};

/// Loads [argv] into a new schema, expecting it to fail.
///
/// Returns the failure.
ParameterException _failure(List<String> argv) =>
    failureOf(() => ReportedParameters().load(argv, environment: _nothing));

/// Tests what a failed load reports and how loaded values are described.
void main() {
  test('three problems at once produce one exception carrying all three', () {
    expect(
      _failure(<String>['--port=eighty', '--moed=production']).violations,
      hasLength(3),
    );
  });

  test('the report names every problem and ends with the listing', () {
    final String report = _failure(<String>[
      '--port=eighty',
      '--moed=production',
    ]).message;

    expect(report, contains('Invalid program parameters (3 problems):'));
    expect(report, contains('is not a valid integer'));
    expect(report, contains('did you mean --mode?'));
    expect(report, contains('APP_DATA_DIR'));
    expect(report, contains('Supported parameters:'));
  });

  test('a single problem is not reported in the plural', () {
    final ParameterException failure = _failure(<String>['--port=1']);

    expect(failure.violations, hasLength(1));
    expect(failure.message, contains('(1 problem):'));
  });

  test('the violations are an ordinary validation report', () {
    final ParameterException failure = _failure(<String>['--port=1']);

    expect(failure.report.subject, 'program parameters');
    expect(failure.report.isValid, isFalse);
    expect(failure.report.errors, hasLength(1));
    expect(
      failure.report.errors.single.code,
      ParameterViolationCodes.missingRequired,
    );
  });

  test('a secret never reaches the report, even when it is what failed', () {
    final ParameterException failure = failureOf(
      () => SecretParameters().load(<String>[
        '--port=$_secret',
      ], environment: _nothing),
    );

    final String report = failure.message;
    expect(report, isNot(contains(_secret)));
    expect(report, contains(_mask));
  });

  test('the usage listing shows names, types, defaults and variables', () {
    final String listing = ReportedParameters().usage();

    expect(listing, contains('--port, -p <int>'));
    expect(listing, contains('The port to listen on.'));
    expect(listing, contains('required'));
    expect(listing, contains('default: production'));
    expect(listing, contains('env: APP_PORT'));
    expect(listing, contains('repeatable'));
  });

  test('the usage listing leaves out the default of a plain flag', () {
    final String listing = ReportedParameters().usage();

    expect(listing, contains('--dry-run'));
    expect(listing, isNot(contains('default: false')));
  });

  test('describing loaded values masks the secret and names each origin', () {
    final parameters = ReportedParameters()
      ..load(
        <String>['--port=8080', '--db-password=$_secret'],
        environment: <String, String>{'APP_DATA_DIR': '/srv/data'},
      );

    final String description = parameters.describe();

    expect(description, isNot(contains(_secret)));
    expect(description, contains('--db-password  $_mask'));
    expect(description, contains('8080 (from the command line)'));
    expect(description, contains('/srv/data (from APP_DATA_DIR)'));
    expect(description, contains('production (default)'));
  });

  test('a schema with no parameters says so', () {
    expect(EmptyParameters().usage(), 'This program takes no parameters.');
  });

  test('a loaded schema with no parameters describes itself the same way', () {
    final parameters = EmptyParameters()
      ..load(const <String>[], environment: _nothing);

    expect(parameters.describe(), 'This program takes no parameters.');
  });
}
