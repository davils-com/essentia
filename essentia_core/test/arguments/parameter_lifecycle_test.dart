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
import 'early_validation_parameters.dart';
import 'named_parameters.dart';
import 'shared_parameters.dart';

/// No environment at all.
const _nothing = <String, String>{};

/// Creates a schema whose `--port` defaults to 8080.
///
/// Returns the schema, not yet loaded.
DefaultedPortParameters _simple() =>
    DefaultedPortParameters(8080, const <int>[]);

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

/// Tests when a schema may be read and how mistakes in declaring one are
/// refused.
void main() {
  group('lifecycle', () {
    test('reading before loading says so instead of reporting a gap', () {
      final DefaultedPortParameters parameters = _simple();

      expect(
        () => parameters.port.value,
        throwsA(
          isA<ParametersNotLoadedError>().having(
            (error) => error.message,
            'message',
            contains('port'),
          ),
        ),
      );
    });

    test('describing before loading says so as well', () {
      expect(_simple().describe, throwsA(isA<ParametersNotLoadedError>()));
    });

    test('the collected leftovers before loading say so as well', () {
      final DefaultedPortParameters parameters = _simple();

      expect(() => parameters.rest, throwsA(isA<ParametersNotLoadedError>()));
      expect(
        () => parameters.unknown,
        throwsA(isA<ParametersNotLoadedError>()),
      );
      expect(
        () => parameters.warnings,
        throwsA(isA<ParametersNotLoadedError>()),
      );
    });

    test('the usage listing needs no load', () {
      expect(_simple().usage(), contains('--port <int>'));
    });

    test('the loaded flag reflects whether load has run', () {
      final DefaultedPortParameters parameters = _simple();

      expect(parameters.isLoaded, isFalse);
      parameters.load(const <String>[], environment: _nothing);
      expect(parameters.isLoaded, isTrue);
    });

    test('loading twice is refused rather than silently ignored', () {
      final DefaultedPortParameters parameters = _simple()
        ..load(<String>['--port=1'], environment: _nothing);

      expect(
        () => parameters.load(<String>['--port=2'], environment: _nothing),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('already loaded'),
          ),
        ),
      );
      expect(parameters.port.value, 1);
    });

    test('a parameter missing from the declared list cannot be read', () {
      final parameters = NamedParameters(<String>['--first'], <String>['--b'])
        ..load(const <String>[], environment: _nothing);

      expect(
        () => parameters.orphan.value,
        throwsA(
          isA<StateError>()
              .having(
                (error) => error,
                'error',
                isNot(isA<ParametersNotLoadedError>()),
              )
              .having(
                (error) => error.message,
                'message',
                contains('not listed in the declared parameters'),
              ),
        ),
      );
      expect(parameters.first.value, isNull);
    });
  });

  group('declaration', () {
    test('a name without a dash is refused', () {
      expect(
        () => NamedParameters(<String>['name'], <String>['--other']),
        _argumentErrorContaining('must start with a dash'),
      );
    });

    test('a short name longer than one character is refused', () {
      expect(
        () => NamedParameters(<String>['-name'], <String>['--other']),
        _argumentErrorContaining('exactly one character'),
      );
    });

    test('a long name with nothing after its dashes is refused', () {
      expect(
        () => NamedParameters(<String>['--'], <String>['--other']),
        _argumentErrorContaining('no name after its dashes'),
      );
    });

    test('a parameter without any name is refused', () {
      expect(
        () => NamedParameters(const <String>[], <String>['--other']),
        _argumentErrorContaining('at least one name'),
      );
    });

    test('the same name declared twice is refused', () {
      expect(
        () => NamedParameters(<String>['--name'], <String>['--name']),
        _argumentErrorContaining('declared more than once'),
      );
    });

    test('a short name declared twice is refused as well', () {
      expect(
        () => NamedParameters(<String>['--first', '-x'], <String>['--b', '-x']),
        _argumentErrorContaining('declared more than once'),
      );
    });

    test('a parameter listed by a second schema is refused', () {
      final Parameter<String?> shared = parameter(<String>['--shared']);
      final first = SharedParameters(shared)
        ..load(<String>['--shared=a'], environment: _nothing);
      expect(
        () => SharedParameters(shared),
        _argumentErrorContaining('declared by another schema'),
      );
      expect(first.shared.value, 'a');
    });

    test('a parameter no schema lists cannot be read', () {
      final Parameter<String?> unlisted = parameter(<String>['--unlisted']);
      expect(
        () => unlisted.value,
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('not listed in the declared parameters'),
          ),
        ),
      );
    });

    test('validation declared before the type is fixed is refused', () {
      expect(
        EarlyValidationParameters.new,
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('Move validate'),
          ),
        ),
      );
    });
  });
}
