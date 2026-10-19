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

import 'package:test/test.dart';

import 'deployment_parameters.dart';
import 'empty_parameters.dart';
import 'secret_parameters.dart';
import 'syntax_parameters.dart';

/// The listing of a schema without an environment prefix.
const _syntaxListing = '''
Supported parameters:
  --name, -n <string>
  --port, -p <int>
  --verbose, -v
  --archive, -a
  --colour             default: true
  --tag, -t <string>   repeatable''';

/// Tests the listing of supported parameters.
void main() {
  test('lists names, types and notes in aligned columns', () {
    expect(SyntaxParameters().usage(), _syntaxListing);
  });

  test('ends no line in trailing spaces', () {
    final List<String> lines = SyntaxParameters().usage().split('\n');

    for (final line in lines) {
      expect(line, isNot(endsWith(' ')));
    }
  });

  test('lists the parameters in the order they are declared', () {
    final String listing = DeploymentParameters().usage();

    final List<int> positions = <String>[
      '--mode',
      '--port',
      '--data-dir',
      '--db-password',
      '--tag',
      '--dry-run',
    ].map(listing.indexOf).toList();

    expect(positions, orderedEquals(List<int>.of(positions)..sort()));
  });

  test('shows a description before the notes', () {
    expect(
      DeploymentParameters().usage(),
      contains('--port, -p <int>        The port to listen on.  required'),
    );
  });

  test('shows the derived environment variables', () {
    final String listing = SecretParameters().usage();

    expect(listing, contains('env: APP_TOKEN'));
    expect(listing, contains('env: APP_TAG'));
    expect(listing, contains('env: APP_PORT'));
  });

  test('shows neither a value nor a default of a sensitive parameter', () {
    final String listing = SecretParameters().usage();

    expect(listing, isNot(contains('default')));
  });

  test('a schema without parameters says so', () {
    expect(EmptyParameters().usage(), 'This program takes no parameters.');
  });

  test('renders the same listing every time', () {
    final parameters = SyntaxParameters();

    expect(parameters.usage(), parameters.usage());
  });
}
