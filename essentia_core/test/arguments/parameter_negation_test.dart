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

import 'cache_parameters.dart';
import 'failure_of.dart';
import 'syntax_parameters.dart';

/// No environment at all.
const _nothing = <String, String>{};

/// Tests which parameters answer to the `--no-` form of their names.
void main() {
  test('a parameter that is not negatable does not answer to --no-', () {
    final ParameterException failure = failureOf(
      () => SyntaxParameters().load(<String>[
        '--no-port',
        '9090',
      ], environment: _nothing),
    );

    final ParameterViolation unknown = failure.violations.first;
    expect(
      unknown,
      isA<UnknownArgument>().having(
        (violation) => violation.token,
        'token',
        '--no-port',
      ),
    );
    final ParameterViolation stray = failure.violations.last;
    expect(
      stray,
      isA<StrayValue>().having(
        (violation) => violation.position,
        'position',
        2,
      ),
    );
  });

  test('a flag declared negatable answers to its negated form', () {
    final parameters = SyntaxParameters()
      ..load(<String>['--no-colour'], environment: _nothing);

    expect(parameters.colour.value, isFalse);
  });

  test('a negated flag given a value is malformed', () {
    final MalformedArgument violation = singleViolation<MalformedArgument>(
      failureOf(
        () => SyntaxParameters().load(<String>[
          '--no-colour=yes',
        ], environment: _nothing),
      ),
    );

    expect(violation.token, '--no-colour');
  });

  test('the negated form of a value parameter never sets it', () {
    final parameters = SyntaxParameters();

    failureOf(
      () =>
          parameters.load(<String>['--no-port', '9090'], environment: _nothing),
    );

    expect(parameters.isLoaded, isFalse);
  });

  test('a declared --no- flag is its own, whichever is declared first', () {
    final first = CacheParameters(noCacheFirst: false)
      ..load(<String>['--no-cache'], environment: _nothing);

    expect(first.noCache.value, isTrue);
    expect(first.cache.value, isFalse);

    final second = CacheParameters(noCacheFirst: true)
      ..load(<String>['--no-cache'], environment: _nothing);

    expect(second.noCache.value, isTrue);
    expect(second.cache.value, isFalse);
  });

  test('a negated name clashing with a declared one is refused', () {
    for (final order in <bool>[false, true]) {
      expect(
        () => CacheParameters(noCacheFirst: order, negatableCache: true),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.toString(),
            'text',
            contains('declared more than once'),
          ),
        ),
      );
    }
  });
}
