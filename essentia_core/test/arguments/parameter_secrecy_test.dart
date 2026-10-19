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
import 'lenient_parameters.dart';
import 'secret_parameters.dart';

/// A value standing in for a key that must never be rendered.
const _placeholder = 'not-a-real-key-value';

/// No environment at all.
const _nothing = <String, String>{};

/// Tests that a value whose parameter is unknown is reported by position.
void main() {
  test(
    'a mistyped sensitive parameter does not put its value in the report',
    () {
      final ParameterException failure = failureOf(
        () => SecretParameters().load(<String>[
          '--tokne',
          _placeholder,
        ], environment: _nothing),
      );

      final String message = failure.message;
      expect(message, isNot(contains(_placeholder)));
      expect(message, contains('--tokne'));
      expect(message, contains('did you mean --token?'));
      expect(message, contains('argument 2'));
    },
  );

  test('a stray value is reported by where it was', () {
    final ParameterException failure = failureOf(
      () => SecretParameters().load(<String>[
        '--token',
        _placeholder,
        'leftover',
      ], environment: _nothing),
    );

    final StrayValue stray = failure.violations.whereType<StrayValue>().single;
    expect(stray.position, 3);
    expect(stray.path.toString(), 'argument 3');
    expect(failure.message, isNot(contains('leftover')));
  });

  test('a collected value is handed over as it was', () {
    final parameters = LenientParameters()
      ..load(<String>['--name=essentia', _placeholder], environment: _nothing);

    expect(parameters.unknown, <String>[_placeholder]);
  });
}
