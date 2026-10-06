/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';
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
