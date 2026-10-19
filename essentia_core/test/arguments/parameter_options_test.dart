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
import 'optioned_parameters.dart';

/// Loads [argv] into a new schema with [environment].
///
/// Returns the loaded schema.
OptionedParameters _load(
  List<String> argv, [
  Map<String, String> environment = const <String, String>{},
]) => OptionedParameters()..load(argv, environment: environment);

/// Tests the options every kind of parameter builder offers: the
/// environment, secrecy, descriptions, deprecation and validation.
void main() {
  test('reads flags, required and defaulted values from their variables', () {
    final OptionedParameters parameters = _load(
      <String>['--id=a1'],
      <String, String>{
        'VERBOSE': 'true',
        'APP_QUIET': 'true',
        'TOKEN': 'abc123',
        'LEVEL': 'debug',
        'APP_MODE': 'slow',
        'APP_LABEL': 'ignored',
      },
    );

    expect(parameters.verbose.value, isTrue);
    expect(parameters.quiet.value, isFalse);
    expect(parameters.token.value, 'abc123');
    expect(parameters.level.value, 'debug');
    expect(parameters.mode.value, 'fast');
    expect(parameters.labels.value, isEmpty);
  });

  test('collects every value of a list parameter', () {
    final OptionedParameters parameters = _load(<String>[
      '--id=a1',
      '--token=abc',
      '--label=a',
      '--label=b',
      '--tag=x',
    ]);

    expect(parameters.labels.value, <String>['a', 'b']);
    expect(parameters.tags.value, <String>['x']);
  });

  test('warns about every deprecated parameter that was given', () {
    final OptionedParameters parameters = _load(<String>[
      '--id=a1',
      '--token=abc',
      '--mode=slow',
      '--tag=x',
    ]);

    expect(
      <String>[
        for (final Violation warning in parameters.warnings)
          '${warning.path} ${warning.message}',
      ],
      unorderedEquals(<String>[
        '--id is deprecated: use --name instead',
        '--mode is deprecated',
        '--tag is deprecated: use --label instead',
      ]),
    );
  });

  test('runs the rules of required and defaulted secrets, withholding '
      'their detail', () {
    const withheld =
        'failed validation - the detail is withheld because the parameter '
        'is sensitive';
    final ParameterException failure = failureOf(
      () => _load(<String>['--id=a1', '--token=ab', '--level=loud']),
    );

    expect(
      <String>[
        for (final Violation violation in failure.violations)
          '${violation.path} ${violation.message}',
      ],
      unorderedEquals(<String>[
        '--token $withheld',
        '--id is deprecated: use --name instead',
        '--level $withheld',
      ]),
    );
  });

  test('lists descriptions and variables in the usage, never secrets', () {
    final String usage = OptionedParameters().usage();

    expect(usage, contains('Talks about everything it does'));
    expect(usage, contains('The name of the instance'));
    expect(usage, contains('How much to log'));
    expect(usage, contains('Labels of the instance'));
    expect(usage, contains('VERBOSE'));
    expect(usage, contains('TOKEN'));
  });

  test('masks secrets when it describes the values', () {
    final String described = _load(<String>[
      '--id=a1',
      '--token=topsecret',
      '--level=warn',
      '--tag=hidden',
    ]).describe();

    expect(described, isNot(contains('topsecret')));
    expect(described, isNot(contains('hidden')));
    expect(described, isNot(contains('warn')));
    expect(described, contains('a1'));
  });
}
