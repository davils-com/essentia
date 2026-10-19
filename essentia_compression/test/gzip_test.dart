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

/// `hello world hello world` as one gzip member, written by zlib.
final Uint8List _helloWorld =
    '1f8b0800000000000003cb48cdc9c95728cf2fca4951c840b0013bcee2ea17000000'
        .hexToByteArray();

/// [length] bytes that compress well and are not all alike.
///
/// Returns the bytes.
Uint8List _sample(int length) {
  final bytes = Uint8List(length);
  var state = 7;
  for (var index = 0; index < length; index++) {
    state = (state * 1103515245 + 12345) % 0x80000000;
    bytes[index] = index % 7 == 0 ? state & 0xFF : 0x61 + index % 5;
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

/// [bytes] with the byte at [index] changed.
///
/// Returns the changed copy.
List<int> _damaged(List<int> bytes, int index) =>
    <int>[...bytes]..[index] = bytes[index] ^ 0x01;

/// Covers gzip compression on every platform: the round trip, the frame it
/// writes and the data it refuses.
void main() {
  test('reads gzip written by zlib', () async {
    expect(utf8.decode(await gunzip(_helloWorld)), 'hello world hello world');
  });

  test('reads back what it wrote', () async {
    for (final length in <int>[0, 1, 100, 70000]) {
      final Uint8List original = _sample(length);

      final Uint8List compressed = await gzip(original);

      expect(await gunzip(compressed), original, reason: '$length bytes');
    }
  });

  test('reads back what it wrote at every level', () async {
    final Uint8List original = _sample(5000);

    for (var level = 0; level <= 9; level++) {
      expect(
        await gunzip(await gzip(original, level: level)),
        original,
        reason: 'level $level',
      );
    }
  });

  test(
    'writes one gzip member with the CRC-32 and length of the data',
    () async {
      final List<int> original = utf8.encode('the frame of RFC 1952');

      final Uint8List compressed = await gzip(original);
      final trailer = ByteData.sublistView(compressed, compressed.length - 8);

      expect(compressed.sublist(0, 3), <int>[0x1F, 0x8B, 0x08]);
      expect(trailer.getUint32(0, Endian.little), Crc32.of(original));
      expect(trailer.getUint32(4, Endian.little), original.length);
    },
  );

  test('compresses data that repeats', () async {
    final List<int> original = utf8.encode('essentia ' * 1000);

    expect((await gzip(original)).length, lessThan(original.length ~/ 10));
  });

  test('streams through chunks of any size', () async {
    final Uint8List original = _sample(40000);

    final List<int> compressed = await _join(
      _chunked(original, 999).transform(gzipEncoder()),
    );
    final List<int> restored = await _join(
      _chunked(compressed, 1).transform(gzipDecoder()),
    );

    expect(restored, original);
  });

  test('takes chunks that are lists of integers', () async {
    final List<int> compressed = await gzip(<int>[104, 105]);

    expect(
      await _join(
        Stream<List<int>>.value(<int>[...compressed]).transform(gzipDecoder()),
      ),
      <int>[104, 105],
    );
  });

  test('refuses a level outside 0 to 9', () {
    expect(() => gzipEncoder(level: 10), throwsRangeError);
    expect(() => gzip(const <int>[], level: -1), throwsRangeError);
  });

  group('refuses', () {
    test('data that is not gzip', () async {
      await expectLater(
        gunzip(utf8.encode('plain text, long enough to be gzip')),
        throwsFormatException,
      );
      await expectLater(
        gunzip(const <int>[0x1F, 0x8B, 0x07]),
        throwsFormatException,
      );
    });

    test('nothing at all', () async {
      await expectLater(gunzip(const <int>[]), throwsFormatException);
    });

    test('a header without data', () async {
      await expectLater(
        gunzip(_helloWorld.sublist(0, 10)),
        throwsFormatException,
      );
    });

    test('data cut short', () async {
      for (final length in <int>[30, 26, 20, 15]) {
        await expectLater(
          gunzip(_helloWorld.sublist(0, length)),
          throwsFormatException,
          reason: '$length bytes',
        );
      }
    });

    test('a damaged CRC-32', () async {
      await expectLater(
        gunzip(_damaged(_helloWorld, _helloWorld.length - 6)),
        throwsFormatException,
      );
    });

    test('a damaged length', () async {
      await expectLater(
        gunzip(_damaged(_helloWorld, _helloWorld.length - 2)),
        throwsFormatException,
      );
    });

    test('damaged compressed data', () async {
      await expectLater(
        gunzip(_damaged(_helloWorld, 15)),
        throwsFormatException,
      );
    });

    test('more than one member', () async {
      final Uint8List second = await gzip(utf8.encode('second member'));

      await expectLater(
        gunzip(<int>[..._helloWorld, ...second]),
        throwsFormatException,
      );
    });

    test('data behind the member', () async {
      await expectLater(
        gunzip(<int>[..._helloWorld, 1, 2, 3]),
        throwsFormatException,
      );
    });
  });

  group('hands on a failure of its input', () {
    test('when compressing', () async {
      final failing = Stream<List<int>>.error(StateError('disk gone'));

      await expectLater(
        failing.transform(gzipEncoder()).toList(),
        throwsStateError,
      );
    });

    test('when decompressing', () async {
      final controller = StreamController<List<int>>();
      final Future<List<Uint8List>> result = controller.stream
          .transform(gzipDecoder())
          .toList();

      controller
        ..add(_helloWorld.sublist(0, 12))
        ..addError(StateError('disk gone'));
      unawaited(controller.close());

      await expectLater(result, throwsStateError);
    });
  });
}
