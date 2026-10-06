/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/arguments.dart';
import 'package:test/test.dart';

import 'failure_of.dart';
import 'long_name_parameters.dart';

/// The report of a load where a name is wider than the path column.
const _report = '''
Invalid program parameters (2 problems):

  --a-parameter-with-a-really-long-name is required but was not given
  --b                           is required but was not given

Supported parameters:
  --a-parameter-with-a-really-long-name <int> required
  --b <int>                           required''';

/// The values of a load where a name is wider than the name column.
const _values = '''
Parameters:
  --a-parameter-with-a-really-long-name 8 (from the command line)
  --b                                 9 (from the command line)''';

/// Tests that a label wider than its column is still separated from the
/// column next to it.
void main() {
  test('the failure report and the listing keep a space after a long name', () {
    final ParameterException failure = failureOf(
      () => LongNameParameters().load(
        const <String>[],
        environment: const <String, String>{},
      ),
    );

    expect(failure.message, _report);
  });

  test('describe keeps a space after a long name', () {
    final parameters = LongNameParameters()
      ..load(<String>[
        '--a-parameter-with-a-really-long-name=8',
        '--b=9',
      ], environment: const <String, String>{});

    expect(parameters.describe(), _values);
  });
}
