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

import 'defaulted_port_parameters.dart';
import 'failure_of.dart';

/// No environment at all.
const _nothing = <String, String>{};

/// Tests that a declared default is held to the rules of its parameter.
void main() {
  test("a default that fails the parameter's own rules is reported", () {
    final ValidationFailure violation = singleViolation<ValidationFailure>(
      failureOf(
        () => DefaultedPortParameters(
          0,
          const <int>[],
        ).load(const <String>[], environment: _nothing),
      ),
    );

    expect(violation.message, 'must be a port number');
    expect(violation.origin, ValueOrigin.defaulted);
    expect(violation.path.toString(), '--port (default)');
  });

  test('a default that satisfies them is used as before', () {
    final parameters = DefaultedPortParameters(8080, const <int>[])
      ..load(const <String>[], environment: _nothing);

    expect(parameters.port.value, 8080);
  });

  test('a default list is checked element by element', () {
    final ParameterException failure = failureOf(
      () => DefaultedPortParameters(8080, const <int>[
        8080,
        0,
      ]).load(const <String>[], environment: _nothing),
    );

    expect(failure.violations.map((violation) => violation.message), <String>[
      'must be a port number',
    ]);
  });

  test('a default list that satisfies the rules is used', () {
    final parameters = DefaultedPortParameters(8080, const <int>[80, 443])
      ..load(const <String>[], environment: _nothing);

    expect(parameters.ports.value, <int>[80, 443]);
  });

  test('a given value overrides the default and is checked itself', () {
    final parameters = DefaultedPortParameters(8080, const <int>[])
      ..load(<String>['--port', '9090'], environment: _nothing);

    expect(parameters.port.value, 9090);
    singleViolation<ValidationFailure>(
      failureOf(
        () => DefaultedPortParameters(
          8080,
          const <int>[],
        ).load(<String>['--port', '70000'], environment: _nothing),
      ),
    );
  });
}
