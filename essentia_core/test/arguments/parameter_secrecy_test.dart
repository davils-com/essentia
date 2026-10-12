/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
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
      ..load(<String>['--name=arc', _placeholder], environment: _nothing);

    expect(parameters.unknown, <String>[_placeholder]);
  });
}
