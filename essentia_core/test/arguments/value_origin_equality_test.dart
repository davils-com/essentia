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

import 'environment_parameters.dart';
import 'failure_of.dart';

/// Tests that an origin is a value, comparable with one a caller builds.
void main() {
  test('two environment origins naming one variable are equal', () {
    expect(
      const EnvironmentOrigin('APP_PORT'),
      EnvironmentOrigin(<String>['APP', 'PORT'].join('_')),
    );
    expect(
      const EnvironmentOrigin('APP_PORT').hashCode,
      EnvironmentOrigin(<String>['APP', 'PORT'].join('_')).hashCode,
    );
  });

  test('two external origins naming one source are equal and different '
      'sources are not', () {
    expect(
      const ExternalOrigin('vault'),
      ExternalOrigin(<String>['vau', 'lt'].join()),
    );
    expect(
      const ExternalOrigin('vault'),
      isNot(const ExternalOrigin('consul')),
    );
  });

  test('an origin names what it describes when printed', () {
    expect('${const EnvironmentOrigin('APP_PORT')}', contains('APP_PORT'));
    expect('${const ExternalOrigin('vault')}', contains('vault'));
    expect('${ValueOrigin.commandLine}', 'CommandLineOrigin');
    expect('${ValueOrigin.defaulted}', 'DefaultOrigin');
  });

  test('a reported origin can be compared with one the caller builds', () {
    final ConversionFailure violation = singleViolation<ConversionFailure>(
      failureOf(
        () => EnvironmentParameters().load(
          const <String>[],
          environment: <String, String>{'APP_PORT': 'eighty'},
        ),
      ),
    );

    expect(violation.origin, const EnvironmentOrigin('APP_PORT'));
  });
}
