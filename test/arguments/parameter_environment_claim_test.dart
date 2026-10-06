/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:test/test.dart';

import 'derived_variable_parameters.dart';
import 'named_variable_parameters.dart';

/// No environment at all.
const _nothing = <String, String>{};

/// Matches an [ArgumentError] whose message contains [fragment].
Matcher _refusedFor(String fragment) => throwsA(
  isA<ArgumentError>().having(
    (error) => error.message,
    'message',
    contains(fragment),
  ),
);

/// Tests that an environment variable belongs to one parameter alone.
void main() {
  test('two parameters deriving the same variable are refused', () {
    expect(
      () => DerivedVariableParameters().load(
        const <String>[],
        environment: _nothing,
      ),
      _refusedFor(
        '"--data-dir" and "--data_dir" both read the environment variable '
        '"APP_DATA_DIR"',
      ),
    );
  });

  test('the collision is refused as the schema is constructed', () {
    expect(DerivedVariableParameters.new, throwsArgumentError);
  });

  test('two parameters declaring the same variable are refused', () {
    expect(
      () => NamedVariableParameters(
        'APP_TOKEN',
        'APP_TOKEN',
      ).load(const <String>[], environment: _nothing),
      _refusedFor('"APP_TOKEN"'),
    );
  });

  test('a variable name no shell could export is refused', () {
    expect(
      () => NamedVariableParameters(
        'not a variable',
        'APP_SECOND',
      ).load(const <String>[], environment: _nothing),
      _refusedFor('is not a well-formed variable name'),
    );
  });

  test('an empty variable name is refused', () {
    expect(
      () => NamedVariableParameters(
        '',
        'APP_SECOND',
      ).load(const <String>[], environment: _nothing),
      throwsArgumentError,
    );
  });

  test('a variable starting with a digit is refused', () {
    expect(
      () => NamedVariableParameters(
        '1_TOKEN',
        'APP_SECOND',
      ).load(const <String>[], environment: _nothing),
      throwsArgumentError,
    );
  });

  test('opting one of them out of the environment resolves the collision', () {
    final parameters = DerivedVariableParameters(separated: true)
      ..load(
        const <String>[],
        environment: <String, String>{'APP_DATA_DIR': '7'},
      );

    expect(parameters.dashed.value, 7);
    expect(parameters.underscored.value, isNull);
  });
}
