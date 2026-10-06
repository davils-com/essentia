/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:math';

import 'package:essentia/essentia.dart';
import 'package:test/test.dart';

import 'colour.dart';
import 'failure_of.dart';
import 'random_text.dart';
import 'typed_parameters.dart';

/// How many cases each property is checked against.
const _cases = 300;

/// No environment at all.
const _nothing = <String, String>{};

/// The units of the readable duration form, largest first.
const _units = <(String, int)>[('d', 86400), ('h', 3600), ('m', 60), ('s', 1)];

/// Loads [argument] into a new schema.
///
/// Returns the loaded schema.
TypedParameters _load(String argument) =>
    TypedParameters()..load(<String>[argument], environment: _nothing);

/// The largest magnitude an integer has on every platform: on the web an
/// integer is a double, exact up to 2^53.
const _largestExactInteger = 0x1FFFFFFFFFFFFF;

/// Draws an integer of either sign whose magnitude is exact on every
/// platform from [random].
///
/// Returns the integer.
int _randomInteger(Random random) {
  final int magnitude =
      (random.nextInt(0x200000) * 0x100000000 + random.nextInt(0xFFFFFFFF)) %
      _largestExactInteger;
  return random.nextBool() ? magnitude : -magnitude;
}

/// Draws a decimal of widely varying magnitude and either sign from
/// [random].
///
/// Returns the decimal.
double _randomDecimal(Random random) =>
    (random.nextDouble() * 2 - 1) * pow(10, random.nextInt(40) - 20);

/// Writes [seconds] down the readable way, largest unit first: `1d 2h 3s`.
///
/// Returns the readable form.
String _readable(int seconds) {
  final parts = <String>[];
  var remaining = seconds;
  for (final (unit, size) in _units) {
    final int amount = remaining ~/ size;
    remaining -= amount * size;
    if (amount > 0) {
      parts.add('$amount$unit');
    }
  }
  if (parts.isEmpty) {
    return '0s';
  }
  return parts.join(' ');
}

/// Capitalises each letter of [text] or not, as [random] decides.
///
/// Returns the text in mixed case.
String _mixedCase(Random random, String text) => text
    .split('')
    .map((letter) => random.nextBool() ? letter.toUpperCase() : letter)
    .join();

/// Expects [parameter] given [rejected] to be reported with the value but
/// without repeating it in the reason.
void _expectRejection(String parameter, String rejected) {
  final ParameterException failure = failureOf(
    () => _load('$parameter=$rejected'),
  );
  final ConversionFailure conversion = failure.violations
      .whereType<ConversionFailure>()
      .single;
  expect(
    conversion.reason,
    isNot(contains(rejected)),
    reason: conversion.message,
  );
  expect(conversion.value, rejected, reason: conversion.message);
}

/// Tests that every built-in converter reads back what was written and
/// rejects what it cannot read without echoing it.
void main() {
  group('a value survives being written down and converted back', () {
    test('int', () {
      final random = Random(1);
      for (var round = 0; round < _cases; round++) {
        final int value = _randomInteger(random);
        expect(_load('--count=$value').count.value, value);
      }
    });

    test('an integer beyond 32 bits', () {
      final random = Random(2);
      for (var round = 0; round < _cases; round++) {
        final int drawn = _randomInteger(random);
        final int value = drawn.isNegative
            ? drawn ~/ 2 - 0x10000000000
            : drawn ~/ 2 + 0x10000000000;
        expect(_load('--size=$value').size.value, value);
      }
    });

    test('double', () {
      final random = Random(3);
      for (var round = 0; round < _cases; round++) {
        final double value = _randomDecimal(random);
        expect(_load('--ratio=$value').ratio.value, value);
      }
    });

    test('duration', () {
      final random = Random(4);
      for (var round = 0; round < _cases; round++) {
        final int seconds = random.nextInt(1000001);
        expect(
          _load('--timeout=${_readable(seconds)}').timeout.value,
          Duration(seconds: seconds),
          reason: _readable(seconds),
        );
      }
    });

    test('path', () {
      final random = Random(5);
      for (var round = 0; round < _cases; round++) {
        final String name = randomText(
          random,
          lowercaseLetters,
          minimum: 1,
          maximum: 12,
        );
        expect(_load('--directory=/tmp/$name').directory.value, '/tmp/$name');
      }
    });

    test('uri', () {
      final random = Random(6);
      for (var round = 0; round < _cases; round++) {
        final String host = randomText(
          random,
          lowercaseLetters,
          minimum: 1,
          maximum: 12,
        );
        final address = 'https://$host.example.com/x';
        expect(_load('--endpoint=$address').endpoint.value, Uri.parse(address));
      }
    });

    test('enum', () {
      final random = Random(7);
      for (var round = 0; round < _cases; round++) {
        final Colour value =
            Colour.values[random.nextInt(Colour.values.length)];
        final String written = _mixedCase(random, value.name);
        expect(_load('--colour=$written').colour.value, value);
      }
    });

    test('application mode', () {
      final random = Random(8);
      for (var round = 0; round < _cases; round++) {
        final ApplicationMode value = ApplicationMode
            .values[random.nextInt(ApplicationMode.values.length)];
        final String written = _mixedCase(random, value.value);
        expect(_load('--mode=$written').mode.value, value);
      }
    });
  });

  group('a converter says what it expected without repeating the value', () {
    test('int', () {
      final random = Random(9);
      for (var round = 0; round < _cases; round++) {
        _expectRejection(
          '--count',
          randomText(random, lowercaseLetters, minimum: 10, maximum: 20),
        );
      }
    });

    test('double', () {
      final random = Random(10);
      for (var round = 0; round < _cases; round++) {
        _expectRejection(
          '--ratio',
          randomText(random, lowercaseLetters, minimum: 10, maximum: 20),
        );
      }
    });

    test('duration', () {
      final random = Random(11);
      for (var round = 0; round < _cases; round++) {
        _expectRejection(
          '--timeout',
          randomText(random, lowercaseLetters, minimum: 10, maximum: 20),
        );
      }
    });

    test('boolean', () {
      final random = Random(12);
      for (var round = 0; round < _cases; round++) {
        _expectRejection(
          '--enabled',
          randomText(random, lowercaseLetters, minimum: 10, maximum: 20),
        );
      }
    });
  });
}
