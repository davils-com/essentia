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
import 'fake_vault.dart';

/// No environment at all.
const _nothing = <String, String>{};

/// Loads [argv] into a new schema, consulting [sources] and [environment].
///
/// Returns the loaded schema.
Future<EnvironmentParameters> _load(
  List<String> argv,
  List<ValueSource> sources, [
  Map<String, String> environment = _nothing,
]) async {
  final parameters = EnvironmentParameters();
  await parameters.loadFrom(argv, sources, environment: environment);
  return parameters;
}

/// Tests the value sources a schema consults after the command line and
/// the environment.
void main() {
  test(
    'a source supplies what the command line and environment did not',
    () async {
      final vault = FakeVault(<String, String>{
        '--token': 'from-vault',
        '--region': 'eu-central',
      });

      final EnvironmentParameters parameters = await _load(
        <String>['--region=argv'],
        <ValueSource>[vault],
      );

      expect(parameters.token.value, 'from-vault');
      expect(parameters.region.value, 'argv');
    },
  );

  test('the environment beats a source', () async {
    final vault = FakeVault(<String, String>{'--token': 'from-vault'});

    final EnvironmentParameters parameters = await _load(
      const <String>[],
      <ValueSource>[vault],
      <String, String>{'APP_TOKEN': 'from-env'},
    );

    expect(parameters.token.value, 'from-env');
  });

  test('a source beats the declared default', () async {
    final vault = FakeVault(<String, String>{'--zone': 'eu-west'});

    final EnvironmentParameters parameters = await _load(
      const <String>[],
      <ValueSource>[vault],
    );

    expect(parameters.zone.value, 'eu-west');
  });

  test('the default is used when no source answers', () async {
    final EnvironmentParameters parameters = await _load(
      const <String>[],
      <ValueSource>[FakeVault(const <String, String>{})],
    );

    expect(parameters.zone.value, 'local');
  });

  test('the first source that answers wins', () async {
    final first = FakeVault(<String, String>{'--token': 'first'});
    final second = FakeVault(<String, String>{
      '--token': 'second',
      '--region': 'second',
    }, name: 'store');

    final EnvironmentParameters parameters = await _load(
      const <String>[],
      <ValueSource>[first, second],
    );

    expect(parameters.token.value, 'first');
    expect(parameters.region.value, 'second');
    expect(second.asked, isNot(contains('--token')));
  });

  test('a source is only asked for what is still without a value', () async {
    final vault = FakeVault(const <String, String>{});

    await _load(
      <String>['--region=argv'],
      <ValueSource>[vault],
      <String, String>{'APP_TOKEN': 'from-env'},
    );

    expect(vault.asked, isNot(contains('--region')));
    expect(vault.asked, isNot(contains('--token')));
    expect(vault.asked, contains('--data-dir'));
    expect(vault.asked.toSet(), hasLength(vault.asked.length));
  });

  test('a value from a source is converted like any other', () async {
    final EnvironmentParameters parameters = await _load(
      const <String>[],
      <ValueSource>[
        FakeVault(<String, String>{'--port': '8080'}),
      ],
    );

    expect(parameters.port.value, 8080);
  });

  test('a bad value from a source names the source it came from', () async {
    final ParameterException failure = await failureOfAsync(
      () => _load(const <String>[], <ValueSource>[
        FakeVault(<String, String>{'--port': 'eighty'}),
      ]),
    );

    final ConversionFailure violation = singleViolation<ConversionFailure>(
      failure,
    );
    expect(violation.origin, const ExternalOrigin('vault'));
    expect(violation.path.toString(), '--port (from vault)');
  });

  test('describing names the source a value came from', () async {
    final EnvironmentParameters parameters = await _load(
      const <String>[],
      <ValueSource>[
        FakeVault(<String, String>{'--token': 'abc'}),
      ],
    );

    expect(parameters.describe(), contains('abc (from vault)'));
  });
}
