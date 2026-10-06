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

/// How many generated cases every property is checked against.
const _cases = 300;

/// What a sensitive value is rendered as.
const _mask = '****';

/// The letters a generated name is made of.
const _letters = 'abcdefghijklmnopqrstuvwxyz';

/// The characters a generated value is made of.
const _alphanumerics =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

/// Draws a string of [minimum] to [maximum] characters out of [alphabet].
///
/// Returns the string.
String _draw(Random random, String alphabet, int minimum, int maximum) {
  final int length = minimum + random.nextInt(maximum - minimum + 1);
  return String.fromCharCodes(
    List<int>.generate(
      length,
      (_) => alphabet.codeUnitAt(random.nextInt(alphabet.length)),
    ),
  );
}

/// Draws a header name of one to twelve letters, the first capitalised, so
/// that it is never written the way it is stored.
///
/// Returns the name.
String _name(Random random) {
  final String letters = _draw(random, _letters, 1, 12);
  return letters[0].toUpperCase() + letters.substring(1);
}

/// Draws a header value of twelve to twenty-four alphanumerics, long enough
/// that it cannot turn up in a rendering by accident.
///
/// Returns the value.
String _value(Random random) => _draw(random, _alphanumerics, 12, 24);

/// Draws up to six headers.
///
/// Returns them, the last of a repeated name winning.
EventHeaders _headers(Random random) {
  final int count = random.nextInt(7);
  final entries = <String, String>{};
  for (var index = 0; index < count; index++) {
    entries[_name(random)] = _value(random);
  }
  return EventHeaders.of(entries);
}

/// Removes from [headers] every header whose value contains [secret], so
/// that the secret cannot turn up in a rendering through an ordinary value
/// that happens to contain it.
///
/// Returns the remaining headers.
EventHeaders _withoutValuesContaining(EventHeaders headers, String secret) =>
    headers.names
        .where((name) => headers[name]?.contains(secret) ?? false)
        .fold(headers, (remaining, name) => remaining.withoutHeader(name));

/// Checks [property] against [_cases] generated cases, each drawn from a
/// random source seeded with [seed] so that a failure can be reproduced.
void _checkAll(int seed, void Function(Random random) property) {
  final random = Random(seed);
  for (var index = 0; index < _cases; index++) {
    property(random);
  }
}

/// Tests the properties every set of headers has, whatever it holds.
void main() {
  group('setting and reading', () {
    test('a header that was set reads back as it was set', () {
      _checkAll(1, (random) {
        final String name = _name(random);
        final String value = _value(random);
        final EventHeaders headers = _headers(random).withHeader(name, value);

        expect(headers[name], value, reason: '$headers');
        expect(headers.contains(name), isTrue, reason: '$headers');
      });
    });

    test('a name matches whatever case it is asked for in', () {
      _checkAll(2, (random) {
        final String name = _name(random);
        final String value = _value(random);
        final EventHeaders headers = EventHeaders.empty.withHeader(name, value);

        expect(headers[name.toLowerCase()], value);
        expect(headers[name.toUpperCase()], value);
        expect(headers.names, <String>{name.toLowerCase()});
      });
    });

    test('setting the same name again replaces it rather than adding to '
        'it', () {
      _checkAll(3, (random) {
        final String name = _name(random);
        final String first = _value(random);
        final String second = _value(random);
        final EventHeaders headers = EventHeaders.empty
            .withHeader(name, first)
            .withHeader(name, second);

        expect(headers[name], second);
        expect(headers.names, hasLength(1));
      });
    });
  });

  group('removing', () {
    test('removing a header removes exactly that one and leaves the '
        'rest', () {
      _checkAll(4, (random) {
        final String name = _name(random);
        final String value = _value(random);
        final EventHeaders headers = _headers(random).withHeader(name, value);

        final EventHeaders without = headers.withoutHeader(name);

        expect(without.contains(name), isFalse, reason: '$headers');
        expect(
          without.names,
          headers.names.difference(<String>{name.toLowerCase()}),
          reason: '$headers',
        );
      });
    });

    test('removing a header that was never set changes nothing', () {
      _checkAll(5, (random) {
        final String name = _name(random);
        final EventHeaders headers = _headers(random).withoutHeader(name);

        expect(headers.withoutHeader(name), headers);
      });
    });
  });

  group('laying one set over another', () {
    test('the empty set is the identity on both sides', () {
      _checkAll(6, (random) {
        final EventHeaders headers = _headers(random);

        expect(EventHeaders.empty + headers, headers);
        expect(headers + EventHeaders.empty, headers);
      });
    });

    test('where both set a name, the one laid on top wins', () {
      _checkAll(7, (random) {
        final String name = _name(random);
        final String under = _value(random);
        final String over = _value(random);
        final EventHeaders combined =
            EventHeaders.empty.withHeader(name, under) +
            EventHeaders.empty.withHeader(name, over);

        expect(combined[name], over);
      });
    });

    test('a value laid over a sensitive one brings its own sensitivity', () {
      _checkAll(8, (random) {
        final String name = _name(random);
        final String secret = _value(random);
        final String ordinary = _value(random);
        final EventHeaders masked = EventHeaders.empty.withHeader(
          name,
          secret,
          sensitive: true,
        );

        final EventHeaders replaced =
            masked + EventHeaders.empty.withHeader(name, ordinary);

        expect(replaced.isSensitive(name), isFalse);
        expect(replaced.toString(), isNot(contains(_mask)));
      });
    });
  });

  group('a sensitive value', () {
    test('is masked in the rendering and readable through the accessor', () {
      _checkAll(9, (random) {
        final String name = _name(random);
        final String secret = _value(random);
        final EventHeaders headers = _withoutValuesContaining(
          _headers(random),
          secret,
        ).withHeader(name, secret, sensitive: true);

        final rendered = headers.toString();

        expect(rendered, isNot(contains(secret)), reason: rendered);
        expect(headers[name], secret, reason: rendered);
        expect(headers.isSensitive(name), isTrue, reason: rendered);
      });
    });
  });
}
