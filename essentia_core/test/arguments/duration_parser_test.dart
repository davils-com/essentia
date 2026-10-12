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
import 'typed_parameters.dart';

/// No environment at all.
const _nothing = <String, String>{};

/// Reads [raw] through a duration parameter.
///
/// Returns the duration.
Duration? _durationOf(String raw) =>
    (TypedParameters()..load(<String>['--timeout=$raw'], environment: _nothing))
        .timeout
        .value;

/// Expects [raw] to be rejected by a duration parameter.
void _expectRejected(String raw) {
  final ConversionFailure violation = singleViolation<ConversionFailure>(
    failureOf(
      () => TypedParameters().load(<String>[
        '--timeout=$raw',
      ], environment: _nothing),
    ),
  );
  expect(violation.value, raw);
  expect(violation.reason, contains('is not a valid duration'));
}

/// Tests the readable and the ISO-8601 forms of a duration.
void main() {
  group('the readable form', () {
    test('reads a single component', () {
      expect(_durationOf('30s'), const Duration(seconds: 30));
      expect(_durationOf('5m'), const Duration(minutes: 5));
      expect(_durationOf('2h'), const Duration(hours: 2));
      expect(_durationOf('3d'), const Duration(days: 3));
    });

    test('reads components separated by spaces', () {
      expect(_durationOf('1h 30m'), const Duration(minutes: 90));
    });

    test('reads components written together', () {
      expect(_durationOf('1h30m'), const Duration(minutes: 90));
    });

    test('reads milliseconds and microseconds', () {
      expect(_durationOf('250ms'), const Duration(milliseconds: 250));
      expect(
        _durationOf('1m 250ms'),
        const Duration(minutes: 1, milliseconds: 250),
      );
      expect(_durationOf('15us'), const Duration(microseconds: 15));
    });

    test('reads a fraction', () {
      expect(_durationOf('1.5h'), const Duration(minutes: 90));
    });

    test('reads a negative duration', () {
      expect(_durationOf('-30s'), const Duration(seconds: -30));
    });

    test('rejects an unknown unit', () {
      _expectRejected('5x');
    });

    test('rejects components out of order', () {
      _expectRejected('30m 1h');
    });

    test('rejects a unit given twice', () {
      _expectRejected('1h 1h');
    });

    test('rejects a number without a unit', () {
      _expectRejected('30');
    });

    test('rejects nothing at all', () {
      _expectRejected('');
    });

    test('rejects words', () {
      _expectRejected('soon');
    });
  });

  group('the ISO-8601 form', () {
    test('reads a time', () {
      expect(_durationOf('PT30S'), const Duration(seconds: 30));
      expect(_durationOf('PT1H30M'), const Duration(minutes: 90));
    });

    test('reads days and a time', () {
      expect(_durationOf('P1DT2H'), const Duration(hours: 26));
    });

    test('reads days alone', () {
      expect(_durationOf('P2D'), const Duration(days: 2));
    });

    test('reads a fraction of a second', () {
      expect(_durationOf('PT0.5S'), const Duration(milliseconds: 500));
    });

    test('ignores capitalisation', () {
      expect(_durationOf('pt30s'), const Duration(seconds: 30));
    });

    test('reads a negative duration', () {
      expect(_durationOf('-PT30S'), const Duration(seconds: -30));
    });

    test('rejects a time designator without a time', () {
      _expectRejected('PT');
    });

    test('rejects a period without anything in it', () {
      _expectRejected('P');
    });

    test('rejects components out of order', () {
      _expectRejected('PT30S1H');
    });
  });
}
