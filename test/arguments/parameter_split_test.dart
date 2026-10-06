/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:test/test.dart';

import 'empty_delimiter_parameters.dart';
import 'split_parameters.dart';

/// No environment at all.
const _nothing = <String, String>{};

/// Tests how a parameter splits its occurrences.
void main() {
  test('an empty delimiter is refused when the parameter is declared', () {
    expect(
      () => EmptyDelimiterParameters().tags,
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.message,
          'message',
          contains('must not be empty'),
        ),
      ),
    );
  });

  test('an empty delimiter is refused on a repeatable parameter as well', () {
    expect(() => EmptyDelimiterParameters().repeated, throwsArgumentError);
  });

  test('a trailing delimiter adds no empty value', () {
    final parameters = SplitParameters()
      ..load(<String>['--tag=a,b,'], environment: _nothing);

    expect(parameters.tags.value, <String>['a', 'b']);
  });

  test('two delimiters in a row add no empty value', () {
    final parameters = SplitParameters()
      ..load(<String>['--tag=a,,b'], environment: _nothing);

    expect(parameters.tags.value, <String>['a', 'b']);
  });

  test('an empty piece is never handed to the converter', () {
    final parameters = SplitParameters()
      ..load(<String>['--port=80,,443,'], environment: _nothing);

    expect(parameters.ports.value, <int>[80, 443]);
  });

  test('the delimiter is matched literally, not as a pattern', () {
    final parameters = SplitParameters()
      ..load(<String>['--word=a.b', '--word=cd'], environment: _nothing);

    expect(parameters.words.value, <String>['a', 'b', 'cd']);
  });
}
