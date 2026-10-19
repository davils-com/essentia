/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:essentia_compression/essentia_compression.dart';
import 'package:test/test.dart';

import 'support/hex_bytes.dart';

/// `hello world hello world` as a zlib stream, written by zlib.
final Uint8List _zlib = '789ccb48cdc9c95728cf2fca4951c840b00169e708d9'
    .hexToByteArray();

/// `hello world hello world` as deflate data alone, written by zlib.
final Uint8List _raw = 'cb48cdc9c95728cf2fca4951c840b001'.hexToByteArray();

/// `hello world hello world` as a zlib stream with a preset dictionary.
final Uint8List _withDictionary =
    '78bb062c0215cb00110ae5f94539290a486c0069e708d9'.hexToByteArray();

/// What the vectors hold.
const _helloWorld = 'hello world hello world';

/// [length] bytes that compress well and are not all alike.
///
/// Returns the bytes.
Uint8List _sample(int length) {
  final bytes = Uint8List(length);
  var state = 11;
  for (var index = 0; index < length; index++) {
    state = (state * 1103515245 + 12345) % 0x80000000;
    bytes[index] = index % 9 == 0 ? state & 0xFF : 0x61 + index % 4;
  }
  return bytes;
}

/// Splits [bytes] into chunks of [size].
///
/// Returns the chunks as a stream.
Stream<List<int>> _chunked(List<int> bytes, int size) =>
    Stream<List<int>>.fromIterable(<List<int>>[
      for (var start = 0; start < bytes.length; start += size)
        bytes.sublist(start, (start + size).clamp(0, bytes.length)),
    ]);

/// Joins the chunks of [stream].
///
/// Returns the bytes.
Future<List<int>> _join(Stream<List<int>> stream) async => <int>[
  for (final List<int> chunk in await stream.toList()) ...chunk,
];

/// Covers deflate compression on every platform: the round trip of both
/// formats, the zlib frame and the data it refuses.
void main() {
  test('reads a zlib stream written by zlib', () async {
    expect(utf8.decode(await inflate(_zlib)), _helloWorld);
  });

  test('reads deflate data alone written by zlib', () async {
    expect(utf8.decode(await inflate(_raw, raw: true)), _helloWorld);
  });

  test('reads back what it wrote, in both formats', () async {
    final Uint8List data = _sample(50000);

    final Uint8List zlib = await deflate(data);
    final Uint8List raw = await deflate(data, raw: true);

    expect(await inflate(zlib), data);
    expect(await inflate(raw, raw: true), data);
    expect(zlib.length, lessThan(data.length ~/ 2));
    expect(zlib[0] & 0x0F, 8);
  });

  test('reads back what it wrote at every level', () async {
    final Uint8List data = _sample(3000);

    for (var level = 0; level <= 9; level++) {
      expect(
        await inflate(await deflate(data, level: level)),
        data,
        reason: '$level',
      );
    }
  });

  test('reads back nothing', () async {
    expect(await inflate(await deflate(const <int>[])), isEmpty);
    expect(
      await inflate(await deflate(const <int>[], raw: true), raw: true),
      isEmpty,
    );
  });

  test('streams through chunks of any size', () async {
    final Uint8List data = _sample(20000);
    final Uint8List compressed = await deflate(data);

    for (final size in <int>[1, 3, 4, 1000]) {
      expect(
        await _join(_chunked(compressed, size).transform(deflateDecoder())),
        data,
        reason: '$size',
      );
    }
    expect(
      await inflate(await _join(_chunked(data, 7).transform(deflateEncoder()))),
      data,
    );
  });

  test('refuses a level outside 0 to 9', () {
    expect(() => deflateEncoder(level: 10), throwsRangeError);
    expect(() => deflate(const <int>[], level: -1), throwsRangeError);
  });

  group('refuses as zlib', () {
    test('data that is not zlib', () async {
      await expectLater(
        inflate(utf8.encode('plain text, not zlib')),
        throwsFormatException,
      );
      await expectLater(inflate(_raw), throwsFormatException);
    });

    test('a header with wrong check bits', () async {
      await expectLater(
        inflate(<int>[0x78, 0x9D, ..._zlib.sublist(2)]),
        throwsFormatException,
      );
    });

    test('a preset dictionary', () async {
      await expectLater(
        inflate(_withDictionary),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('preset dictionary'),
          ),
        ),
      );
    });

    test('nothing at all and too little', () async {
      await expectLater(inflate(const <int>[]), throwsFormatException);
      await expectLater(
        inflate(const <int>[0x78, 0x9C]),
        throwsFormatException,
      );
    });

    test('data cut short', () async {
      for (final length in <int>[21, 19, 18, 12]) {
        await expectLater(
          inflate(_zlib.sublist(0, length)),
          throwsFormatException,
          reason: '$length bytes',
        );
      }
    });

    test('a damaged Adler-32', () async {
      await expectLater(
        inflate(<int>[..._zlib]..[_zlib.length - 1] ^= 0x01),
        throwsFormatException,
      );
    });

    test('data behind the stream', () async {
      await expectLater(
        inflate(<int>[..._zlib, 1, 2, 3]),
        throwsFormatException,
      );
    });
  });

  group('hands on a failure of its input', () {
    test('when compressing', () async {
      final failing = Stream<List<int>>.error(StateError('disk gone'));

      await expectLater(
        failing.transform(deflateEncoder()).toList(),
        throwsStateError,
      );
    });

    test('when decompressing', () async {
      final controller = StreamController<List<int>>();
      final Future<List<Uint8List>> result = controller.stream
          .transform(deflateDecoder())
          .toList();

      controller
        ..add(_zlib.sublist(0, 6))
        ..addError(StateError('disk gone'));
      unawaited(controller.close());

      await expectLater(result, throwsStateError);
    });
  });
}
