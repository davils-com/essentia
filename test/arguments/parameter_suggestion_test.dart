/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';
import 'package:test/test.dart';

import 'failure_of.dart';
import 'many_flag_parameters.dart';

/// No environment at all.
const _nothing = <String, String>{};

/// How long the huge unknown argument is.
const _hugeTokenLength = 1000000;

/// Loads [argv], which holds one unknown argument.
///
/// Returns the violation reporting it.
UnknownArgument _unknownOf(List<String> argv) =>
    singleViolation<UnknownArgument>(
      failureOf(() => ManyFlagParameters().load(argv, environment: _nothing)),
    );

/// Tests that the "did you mean" search stays cheap.
void main() {
  test('a near miss still gets a suggestion', () {
    expect(_unknownOf(<String>['--moed']).suggestion, '--mode');
  });

  test('a near miss of a long name still gets a suggestion', () {
    expect(
      _unknownOf(<String>['--parameter-numbr-2']).suggestion,
      '--parameter-number-2',
    );
  });

  test('an unknown argument far longer than any name gets no suggestion', () {
    expect(
      _unknownOf(<String>['--parameter-number-0-and-a-great-deal-more-text'])
          .suggestion,
      isNull,
    );
  });

  test(
    'a huge unknown argument is reported without searching for a suggestion',
    () {
      final token = '--${'a' * _hugeTokenLength}';

      expect(_unknownOf(<String>[token]).suggestion, isNull);
    },
    timeout: const Timeout(Duration(seconds: 10)),
  );
}
