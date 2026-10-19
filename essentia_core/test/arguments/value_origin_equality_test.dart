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
