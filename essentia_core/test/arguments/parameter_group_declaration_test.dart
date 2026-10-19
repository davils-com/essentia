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
import 'grouped_parameters.dart';
import 'stray_group_parameters.dart';

/// No environment at all.
const _nothing = <String, String>{};

/// Matches an [ArgumentError] whose text contains [fragment].
///
/// Returns the matcher.
Matcher _argumentErrorContaining(String fragment) => throwsA(
  isA<ArgumentError>().having(
    (error) => error.toString(),
    'text',
    contains(fragment),
  ),
);

/// Tests that a group naming a parameter missing from the declared list is
/// refused as a mistake in the schema.
void main() {
  test('an exclusive group naming an undeclared parameter is refused', () {
    final schema = StrayGroupParameters.clashing();

    expect(
      () => schema.load(<String>['--quiet'], environment: _nothing),
      _argumentErrorContaining('"--timeout"'),
    );
    expect(
      () => StrayGroupParameters.clashing().load(<String>[
        '--quiet',
      ], environment: _nothing),
      _argumentErrorContaining('not a declared parameter'),
    );
  });

  test('a dependency naming an undeclared parameter is refused', () {
    expect(
      () => StrayGroupParameters.dependent().load(<String>[
        '--user',
        'essentia',
      ], environment: _nothing),
      _argumentErrorContaining('"--password"'),
    );
  });

  test('the schema is refused before the resolving pass, not during it', () {
    final schema = StrayGroupParameters.clashing();

    expect(
      () => schema.load(<String>['--quiet'], environment: _nothing),
      throwsArgumentError,
    );
    expect(schema.isLoaded, isFalse);
  });

  test('a group of declared parameters still reports what input got wrong', () {
    final ParameterException failure = failureOf(
      () => GroupedParameters().load(<String>[
        '--token=abc',
        '--key-file=/tmp/key',
      ], environment: _nothing),
    );

    expect(failure.violations, hasLength(1));
  });
}
