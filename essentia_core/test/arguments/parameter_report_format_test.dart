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

import 'deployment_parameters.dart';
import 'failure_of.dart';

/// The complete report of a load that went wrong in four ways.
const _expected = '''
Invalid program parameters (4 problems):

  --moed         is not a known parameter - did you mean --mode?
  --port         'eighty' is not a valid integer
  --data-dir     is required but was not given, and APP_DATA_DIR is not set
  --db-password  is required but was not given, and APP_DB_PASSWORD is not set

Supported parameters:
  --mode <mode>           default: production  env: APP_MODE
  --port, -p <int>        The port to listen on.  required  env: APP_PORT
  --data-dir <path>       required  env: APP_DATA_DIR
  --db-password <string>  required  env: APP_DB_PASSWORD
  --tag <string>          repeatable  env: APP_TAG
  --dry-run               env: APP_DRY_RUN''';

/// Tests the exact rendering of a failed load.
void main() {
  test('a failed load renders every problem and the listing in one report', () {
    final ParameterException failure = failureOf(
      () => DeploymentParameters().load(<String>[
        '--port=eighty',
        '--moed=production',
      ], environment: const <String, String>{}),
    );

    expect(failure.message, _expected);
    expect(failure.toString(), _expected);
    expect(failure.report.render(), _expected);
  });

  test('the usage carried by the failure is the listing of the schema', () {
    final ParameterException failure = failureOf(
      () => DeploymentParameters().load(
        const <String>[],
        environment: const <String, String>{},
      ),
    );

    expect(failure.usage, DeploymentParameters().usage());
  });
}
