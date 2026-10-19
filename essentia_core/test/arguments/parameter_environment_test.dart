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
import 'mandatory_parameters.dart';

/// Loads [argv] into a new schema with [environment].
///
/// Returns the loaded schema.
EnvironmentParameters _load(
  List<String> argv,
  Map<String, String> environment,
) => EnvironmentParameters()..load(argv, environment: environment);

/// Tests the fallback from the command line to the environment.
void main() {
  test('a parameter falls back to the variable derived from its name', () {
    expect(
      _load(const <String>[], <String, String>{
        'APP_DATA_DIR': '/srv/data',
      }).dataDir.value,
      '/srv/data',
    );
  });

  test('the command line beats the environment', () {
    expect(
      _load(
        <String>['--data-dir=/from/argv'],
        <String, String>{'APP_DATA_DIR': '/from/env'},
      ).dataDir.value,
      '/from/argv',
    );
  });

  test('an explicitly named variable replaces the derived one', () {
    expect(
      _load(const <String>[], <String, String>{
        'VAULT_KEY': 's3cret',
        'APP_SECRET_KEY': 'ignored',
      }).secretKey.value,
      's3cret',
    );
  });

  test('a parameter that opted out is not fed from the environment', () {
    expect(
      _load(const <String>[], <String, String>{
        'APP_LOCAL': 'value',
      }).local.value,
      isNull,
    );
  });

  test('a flag can be turned on through the environment', () {
    expect(
      _load(const <String>[], <String, String>{
        'APP_EAGER': 'true',
      }).eager.value,
      isTrue,
    );
  });

  test('a value from the environment is converted like any other', () {
    expect(
      _load(const <String>[], <String, String>{'APP_PORT': '8080'}).port.value,
      8080,
    );
  });

  test('a bad value from the environment is reported under the variable', () {
    final ConversionFailure violation = singleViolation<ConversionFailure>(
      failureOf(
        () => _load(const <String>[], <String, String>{'APP_PORT': 'eighty'}),
      ),
    );

    expect(violation.origin, const EnvironmentOrigin('APP_PORT'));
    expect(violation.path.toString(), 'APP_PORT');
  });

  test('a missing required parameter names the variable it would read', () {
    final MissingRequiredParameter violation =
        singleViolation<MissingRequiredParameter>(
          failureOf(
            () => MandatoryParameters(environmentPrefix: 'APP')
                .load(const <String>[], environment: const <String, String>{}),
          ),
        );

    expect(violation.message, contains('APP_PORT'));
  });

  test('without a prefix a missing parameter names no variable', () {
    final MissingRequiredParameter violation =
        singleViolation<MissingRequiredParameter>(
          failureOf(
            () => MandatoryParameters().load(
              const <String>[],
              environment: const <String, String>{},
            ),
          ),
        );

    expect(violation.message, 'is required but was not given');
  });

  test('describing names the variable a value came from', () {
    expect(
      _load(const <String>[], <String, String>{
        'APP_DATA_DIR': '/srv/data',
      }).describe(),
      contains('/srv/data (from APP_DATA_DIR)'),
    );
  });
}
