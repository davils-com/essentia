/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:typed_data';

import 'package:essentia/src/bytes/byte_string.dart';
import 'package:essentia/src/bytes/hex_format.dart';
import 'package:test/test.dart';

/// Covers the immutable byte string.
void main() {
  test('copies what it is made from', () {
    final bytes = Uint8List.fromList(<int>[1, 2, 3]);

    final value = ByteString(bytes);
    bytes[0] = 9;

    expect(value[0], 1);
    expect(value.size, 3);
  });

  test('keeps the low eight bits of every element', () {
    expect(ByteString(const <int>[0x101, -1]).toByteArray(), <int>[1, 255]);
  });

  test('hands out a view that cannot change it', () {
    final value = ByteString(const <int>[1]);

    expect(() => value.bytes[0] = 2, throwsUnsupportedError);
    expect(value.bytes, <int>[1]);
  });

  test('hands out copies the caller owns', () {
    final value = ByteString(const <int>[1, 2, 3]);

    final Uint8List copy = value.toByteArray(1);
    copy[0] = 7;

    expect(copy, <int>[7, 3]);
    expect(value[1], 2);
  });

  test('the empty byte string has no bytes', () {
    expect(ByteString.empty.isEmpty, isTrue);
    expect(ByteString.empty.isNotEmpty, isFalse);
    expect(ByteString(const <int>[0]).isNotEmpty, isTrue);
  });

  test('takes a range of bytes', () {
    final ByteString value = 'abcdef'.encodeToByteString();

    expect(value.substring(1, 3).decodeToString(), 'bc');
    expect(value.substring(4).decodeToString(), 'ef');
  });

  test('knows its prefixes and suffixes', () {
    final ByteString value = 'abc'.encodeToByteString();

    expect(value.startsWith('ab'.encodeToByteString()), isTrue);
    expect(value.startsWith('b'.encodeToByteString()), isFalse);
    expect(value.startsWith('abcd'.encodeToByteString()), isFalse);
    expect(value.endsWith('bc'.encodeToByteString()), isTrue);
    expect(value.endsWith('b'.encodeToByteString()), isFalse);
    expect(value.endsWith('zabc'.encodeToByteString()), isFalse);
  });

  test('finds a byte', () {
    final value = ByteString(const <int>[5, 6, 5]);

    expect(value.indexOf(5), 0);
    expect(value.indexOf(5, 1), 2);
    expect(value.indexOf(7), -1);
  });

  test('writes and reads hexadecimal digits', () {
    final ByteString value = 'CAFE'.hexToByteString();

    expect(value.toHexString(), 'cafe');
    expect(value.toHexString(HexFormat.upperCaseFormat), 'CAFE');
    expect('ca:fe'.hexToByteString(const HexFormat(byteSeparator: ':')), value);
  });

  test('decodes malformed UTF-8 to the replacement character', () {
    expect(ByteString(const <int>[0xff]).decodeToString(), '\u{FFFD}');
  });

  test('is equal by its bytes and shares the hash code', () {
    final ByteString left = <int>[1, 2].toByteString();
    final right = ByteString(const <int>[1, 2]);

    expect(left, right);
    expect(left.hashCode, right.hashCode);
    expect(left, isNot(ByteString(const <int>[1, 3])));
  });

  test('sorts by its bytes read unsigned, then by its size', () {
    final low = ByteString(const <int>[0x01]);
    final high = ByteString(const <int>[0xff]);
    final longer = ByteString(const <int>[0x01, 0x00]);

    expect(low.compareTo(high), isNegative);
    expect(high.compareTo(low), isPositive);
    expect(low.compareTo(longer), isNegative);
    expect(low.compareTo(ByteString(const <int>[0x01])), 0);
  });

  test('renders as Kotlin does', () {
    expect(
      ByteString(const <int>[1, 2, 3]).toString(),
      'ByteString(size=3 hex=010203)',
    );
  });
}
