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
