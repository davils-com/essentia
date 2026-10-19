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

import 'choice_default_parameters.dart';
import 'failure_of.dart';

/// No environment at all.
const _nothing = <String, String>{};

/// Tests that a declared default is held to the constraint its conversion
/// installed.
void main() {
  group('a choice', () {
    test('refuses a default that is not one of its choices, under the '
        'default origin', () {
      final ConversionFailure violation = singleViolation<ConversionFailure>(
        failureOf(
          () =>
              ChoiceDefaultParameters(levelDefault: 'medium')
                  .load(const <String>[], environment: _nothing),
        ),
      );

      expect(violation.origin, ValueOrigin.defaulted);
      expect(violation.code, ParameterViolationCodes.conversionFailed);
      expect(violation.path.toString(), '--level (default)');
      expect(violation.message, "'medium' is not one of low, high");
    });

    test('accepts a default that is one of its choices', () {
      final parameters = ChoiceDefaultParameters()
        ..load(const <String>[], environment: _nothing);

      expect(parameters.level.value, 'low');
    });

    test('does not consult the default when a value is given', () {
      final parameters = ChoiceDefaultParameters(levelDefault: 'medium')
        ..load(<String>['--level=high'], environment: _nothing);

      expect(parameters.level.value, 'high');
    });

    test("checks every element of a repeated parameter's default", () {
      final ConversionFailure violation = singleViolation<ConversionFailure>(
        failureOf(
          () =>
              ChoiceDefaultParameters(levelsDefault: <String>['low', 'medium'])
                  .load(const <String>[], environment: _nothing),
        ),
      );

      expect(violation.message, "'medium' is not one of low, high");
    });

    test('masks a sensitive default it refuses', () {
      final ParameterException failure = failureOf(
        () =>
            ChoiceDefaultParameters(tierDefault: 'platinum-placeholder')
                .load(const <String>[], environment: _nothing),
      );
      final ConversionFailure violation = singleViolation<ConversionFailure>(
        failure,
      );

      expect(violation.value, '****');
      expect(failure.toString(), isNot(contains('platinum-placeholder')));
    });
  });

  test('a bad default does not hide a bad argument', () {
    final ParameterException failure = failureOf(
      () =>
          ChoiceDefaultParameters(levelDefault: 'medium')
              .load(<String>['--unknown'], environment: _nothing),
    );

    expect(
      failure.violations.map((violation) => violation.code),
      <ViolationCode>[
        ParameterViolationCodes.unknownArgument,
        ParameterViolationCodes.conversionFailed,
      ],
    );
  });
}
