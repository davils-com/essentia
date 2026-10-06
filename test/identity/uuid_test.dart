/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:typed_data';

import 'package:essentia/essentia.dart';
import 'package:test/test.dart';

/// A well-formed version 4 identifier.
const _v4Text = '3f2504e0-4f89-41d3-9a0c-0305e82c3301';

/// A well-formed version 7 identifier.
const _v7Text = '0199c3f0-8a1c-7c2e-9b4d-5f6a7b8c9d0e';

/// Texts that no parser accepts.
const _refused = <String>[
  '',
  'not-a-uuid',
  '0199c3f0-8a1c-7c2e-9b4d-5f6a7b8c9d0',
  '0199c3f0-8a1c-7c2e-9b4d-5f6a7b8c9d0ee',
  '0199c3f0:8a1c:7c2e:9b4d:5f6a7b8c9d0e',
  '0199c3f0-8a1c-1c2e-9b4d-5f6a7b8c9d0e',
  '0199c3f0-8a1c-7c2e-0b4d-5f6a7b8c9d0e',
];

/// Matches a [FormatException] whose message contains [fragment].
Matcher _refusalSaying(String fragment) => throwsA(
  isA<FormatException>().having(
    (refusal) => refusal.message,
    'message',
    contains(fragment),
  ),
);

/// Tests what every identifier has in common, whichever version it is.
void main() {
  test('a text form is read back as the version it says it is', () {
    expect(Uuid.parse(_v4Text), isA<UuidV4>());
    expect(Uuid.parse(_v7Text), isA<UuidV7>());
  });

  test('an identifier reports its own version', () {
    expect(UuidV4.random().version, UuidVersion.random);
    expect(UuidV7.random().version, UuidVersion.timeOrdered);
    expect(UuidVersion.random.number, 4);
    expect(UuidVersion.timeOrdered.number, 7);
  });

  test('an identifier reads back as itself, whatever route it took', () {
    final minted = UuidV7.random();

    expect(Uuid.parse(minted.toString()), minted);
    expect(UuidV7.parse(minted.toString()), minted);
    expect(Uuid.parse(minted.toString().toUpperCase()), minted);
  });

  test('identifiers of different versions are never equal', () {
    expect(UuidV4.random(), isNot(equals(UuidV7.random())));
  });

  test('equality and hashing are over the whole value', () {
    final minted = UuidV7.random();
    final same = UuidV7.parse(minted.toString());

    expect(same, minted);
    expect(same.hashCode, minted.hashCode);
    expect(minted, isNot(equals(minted.toString())));
  });

  group('what is not an identifier', () {
    test('is refused by every parser', () {
      for (final String text in _refused) {
        expect(Uuid.tryParse(text), isNull, reason: text);
        expect(UuidV4.tryParse(text), isNull, reason: text);
        expect(UuidV7.tryParse(text), isNull, reason: text);
        expect(() => Uuid.parse(text), throwsFormatException, reason: text);
        expect(() => UuidV4.parse(text), throwsFormatException, reason: text);
        expect(() => UuidV7.parse(text), throwsFormatException, reason: text);
      }
    });

    test('says what is wrong with it', () {
      expect(() => Uuid.parse('abc'), _refusalSaying('3 characters'));
      expect(
        () => Uuid.parse('0199c3f0-8a1c-1c2e-9b4d-5f6a7b8c9d0e'),
        _refusalSaying('version Essentia mints'),
      );
    });
  });

  test('a parser refuses the version it is not for', () {
    expect(UuidV4.tryParse(_v7Text), isNull);
    expect(UuidV7.tryParse(_v4Text), isNull);
    expect(() => UuidV4.parse(_v7Text), throwsFormatException);
    expect(() => UuidV7.parse(_v4Text), throwsFormatException);
  });

  test('the byte form round-trips through the text form', () {
    final minted = UuidV7.random();
    final Uint8List bytes = minted.toBytes();

    expect(bytes, hasLength(16));
    expect(Uuid.parse(minted.toString()).toBytes(), bytes);
  });

  test('the byte form is a copy, so changing it changes nothing', () {
    final minted = UuidV4.random();
    final Uint8List bytes = minted.toBytes();
    bytes[6] = 0;

    expect(minted.toBytes(), isNot(equals(bytes)));
    expect(minted.toBytes()[6] ~/ 16, 4);
  });
}
