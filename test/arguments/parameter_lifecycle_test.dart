/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/arguments.dart';
import 'package:test/test.dart';

import 'defaulted_port_parameters.dart';
import 'early_validation_parameters.dart';
import 'named_parameters.dart';

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
        NamedParameters(<String>['name'], <String>['--other']).usage,
        _argumentErrorContaining('must start with a dash'),
      );
    });

    test('a short name longer than one character is refused', () {
      expect(
        NamedParameters(<String>['-name'], <String>['--other']).usage,
        _argumentErrorContaining('exactly one character'),
      );
    });

    test('a long name with nothing after its dashes is refused', () {
      expect(
        NamedParameters(<String>['--'], <String>['--other']).usage,
        _argumentErrorContaining('no name after its dashes'),
      );
    });

    test('a parameter without any name is refused', () {
      expect(
        NamedParameters(const <String>[], <String>['--other']).usage,
        _argumentErrorContaining('at least one name'),
      );
    });

    test('the same name declared twice is refused', () {
      expect(
        NamedParameters(<String>['--name'], <String>['--name']).usage,
        _argumentErrorContaining('declared more than once'),
      );
    });

    test('a short name declared twice is refused as well', () {
      expect(
        NamedParameters(<String>['--first', '-x'], <String>['--b', '-x']).usage,
        _argumentErrorContaining('declared more than once'),
      );
    });

    test('validation declared before the type is fixed is refused', () {
      expect(
        EarlyValidationParameters().usage,
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
