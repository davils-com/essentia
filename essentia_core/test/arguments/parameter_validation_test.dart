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
import 'mandatory_parameters.dart';
import 'validated_parameters.dart';

/// No environment at all.
const _nothing = <String, String>{};

/// Tests the rules, groups and requirements a schema declares.
void main() {
  group('rules', () {
    test('a value that satisfies its rule is kept', () {
      final parameters = ValidatedParameters()
        ..load(<String>['--port=8080'], environment: _nothing);

      expect(parameters.port.value, 8080);
    });

    test('a value that fails its rule is reported with its own message', () {
      final ValidationFailure violation = singleViolation<ValidationFailure>(
        failureOf(
          () => ValidatedParameters().load(<String>[
            '--port=70000',
          ], environment: _nothing),
        ),
      );

      expect(violation.message, 'must be a valid TCP port');
      expect(violation.code, ParameterViolationCodes.validationFailed);
      expect(violation.origin, ValueOrigin.commandLine);
      expect(violation.path.toString(), '--port');
    });

    test('every rule declared for one parameter runs', () {
      final ParameterException failure = failureOf(
        () => ValidatedParameters().load(<String>[
          '--name=${' ' * 9}',
        ], environment: _nothing),
      );

      expect(failure.violations.map((violation) => violation.message), <String>[
        'must not be blank',
        'must be at most 8 characters',
      ]);
    });

    test('a rule on a repeatable parameter runs against each element', () {
      final ParameterException failure = failureOf(
        () => ValidatedParameters().load(<String>[
          '--weight=1',
          '--weight=-2',
          '--weight=-3',
        ], environment: _nothing),
      );

      expect(failure.violations, hasLength(2));
    });

    test('a repeatable parameter whose elements pass keeps them all', () {
      final parameters = ValidatedParameters()
        ..load(<String>['--weight=1', '--weight=2'], environment: _nothing);

      expect(parameters.weights.value, <int>[1, 2]);
    });
  });

  group('groups', () {
    test('one of a mutually exclusive pair is fine', () {
      final parameters = GroupedParameters()
        ..load(<String>['--token=abc'], environment: _nothing);

      expect(parameters.token.value, 'abc');
      expect(parameters.keyFile.value, isNull);
    });

    test('both of a mutually exclusive pair is reported', () {
      final MutuallyExclusiveParameters violation =
          singleViolation<MutuallyExclusiveParameters>(
            failureOf(
              () => GroupedParameters().load(<String>[
                '--token=abc',
                '--key-file=/tmp/key',
              ], environment: _nothing),
            ),
          );

      expect(
        violation.parameters.map((parameter) => parameter.primaryName),
        <String>['--token', '--key-file'],
      );
      expect(violation.path.toString(), '--token, --key-file');
    });

    test('a parameter given without what it depends on is reported', () {
      final MissingDependency violation = singleViolation<MissingDependency>(
        failureOf(
          () => GroupedParameters().load(<String>[
            '--password=secret',
          ], environment: _nothing),
        ),
      );

      expect(
        violation.missing.map((parameter) => parameter.primaryName),
        <String>['--user'],
      );
      expect(violation.message, 'requires --user');
    });

    test('a parameter given with what it depends on is fine', () {
      final parameters = GroupedParameters()
        ..load(<String>[
          '--password=secret',
          '--user=nils',
        ], environment: _nothing);

      expect(parameters.password.value, 'secret');
    });

    test('the parameter depended on may be given alone', () {
      final parameters = GroupedParameters()
        ..load(<String>['--user=nils'], environment: _nothing);

      expect(parameters.user.value, 'nils');
    });
  });

  group('required parameters', () {
    test('a required parameter that is given reads as a value', () {
      final parameters = MandatoryParameters()
        ..load(<String>['--port=8080'], environment: _nothing);

      expect(parameters.port.value, 8080);
      expect(parameters.host.value, 'localhost');
    });

    test('a required parameter that is absent is reported', () {
      final MissingRequiredParameter violation =
          singleViolation<MissingRequiredParameter>(
            failureOf(
              () => MandatoryParameters().load(
                const <String>[],
                environment: _nothing,
              ),
            ),
          );

      expect(violation.parameter.primaryName, '--port');
      expect(violation.code, ParameterViolationCodes.missingRequired);
    });

    test('a declared default is used when nothing supplies a value', () {
      final parameters = MandatoryParameters()
        ..load(<String>['--port=1'], environment: _nothing);

      expect(parameters.host.value, 'localhost');
    });

    test('a given value beats the declared default', () {
      final parameters = MandatoryParameters()
        ..load(<String>[
          '--port=1',
          '--host=example.com',
        ], environment: _nothing);

      expect(parameters.host.value, 'example.com');
    });
  });
}
