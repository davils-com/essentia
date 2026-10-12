/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:math';

import 'package:essentia_core/essentia_core.dart';
import 'package:test/test.dart';

import 'failure_of.dart';
import 'random_text.dart';
import 'secret_parameters.dart';
import 'syntax_parameters.dart';

/// How many cases each property is checked against.
const _cases = 200;

/// What a masked value is rendered as.
const _mask = '****';

/// No environment at all.
const _nothing = <String, String>{};

/// Draws a secret of letters and digits from [random].
///
/// Returns the secret.
String _secret(Random random) =>
    randomText(random, alphanumerics, minimum: 12, maximum: 32);

/// Draws a lowercase word no integer converter accepts from [random].
///
/// Returns the word.
String _unparseable(Random random) =>
    randomText(random, lowercaseLetters, minimum: 12, maximum: 32);

/// Tests that a sensitive value never reaches anything Essentia renders.
void main() {
  test('a sensitive value never reaches the resolved state report', () {
    final random = Random(21);
    for (var round = 0; round < _cases; round++) {
      final String secret = _secret(random);
      final parameters = SecretParameters()
        ..load(<String>['--token=$secret'], environment: _nothing);

      final String description = parameters.describe();

      expect(description, isNot(contains(secret)), reason: description);
      expect(description, contains(_mask), reason: description);
    }
  });

  test('a sensitive value from the environment never reaches the report', () {
    final random = Random(22);
    for (var round = 0; round < _cases; round++) {
      final String secret = _secret(random);
      final parameters = SecretParameters()
        ..load(
          const <String>[],
          environment: <String, String>{'APP_TOKEN': secret},
        );

      final String description = parameters.describe();

      expect(description, isNot(contains(secret)), reason: description);
    }
  });

  test('a sensitive value never reaches the report from inside a list', () {
    final random = Random(23);
    for (var round = 0; round < _cases; round++) {
      final String secret = _secret(random);
      final parameters = SecretParameters()
        ..load(<String>[
          '--token=$secret',
          '--tag=$secret',
          '--tag=$secret',
        ], environment: _nothing);

      final String description = parameters.describe();

      expect(description, isNot(contains(secret)), reason: description);
      expect(description, contains('[$_mask, $_mask]'), reason: description);
    }
  });

  test('a conversion failure about a sensitive value omits the value', () {
    final random = Random(24);
    for (var round = 0; round < _cases; round++) {
      final String rejected = _unparseable(random);

      final ParameterException failure = failureOf(
        () => SecretParameters().load(<String>[
          '--token=irrelevant-but-long-enough',
          '--port=$rejected',
        ], environment: _nothing),
      );

      final String report = failure.message;
      expect(report, isNot(contains(rejected)), reason: report);
      expect(
        failure.violations.whereType<ConversionFailure>().single.value,
        _mask,
      );
    }
  });

  test('the usage listing never carries a value at all', () {
    final random = Random(25);
    for (var round = 0; round < _cases; round++) {
      final String secret = _secret(random);
      final parameters = SecretParameters()
        ..load(<String>['--token=$secret'], environment: _nothing);

      final String usage = parameters.usage();

      expect(usage, isNot(contains(secret)), reason: usage);
    }
  });

  test('a malformed argument never carries what followed its equals sign', () {
    final random = Random(26);
    for (var round = 0; round < _cases; round++) {
      final String secret = _secret(random);

      final ParameterException failure = failureOf(
        () => SecretParameters().load(<String>[
          '--=$secret',
        ], environment: _nothing),
      );

      final String report = failure.message;
      expect(report, isNot(contains(secret)), reason: report);
    }
  });

  test('a negated flag given a value never carries the value', () {
    final random = Random(27);
    for (var round = 0; round < _cases; round++) {
      final String secret = _secret(random);

      final ParameterException failure = failureOf(
        () => SyntaxParameters().load(<String>[
          '--no-colour=$secret',
        ], environment: _nothing),
      );

      final String report = failure.message;
      expect(report, isNot(contains(secret)), reason: report);
      expect(report, contains('--no-colour'), reason: report);
    }
  });
}
