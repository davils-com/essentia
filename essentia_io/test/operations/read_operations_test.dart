/*
 * Copyright 2026 Davils
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:typed_data';

import 'package:essentia_core/essentia_core.dart';
import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:essentia_coroutines/testing.dart';
import 'package:essentia_io/essentia_io.dart';
import 'package:test/test.dart';

/// A channel whose writer hands over [chunks] one at a time, each in its
/// own flush, and closes it.
///
/// Returns the channel.
ByteChannel _arriving(CoroutineScope scope, List<List<int>> chunks) {
  final channel = ByteChannel();
  scope.launch((it) async {
    for (final chunk in chunks) {
      await channel.writeFully(chunk);
      await channel.flush();
      await yieldNow();
    }
    await channel.flushAndClose();
  });
  return channel;
}

/// Covers the reading operations of a channel.
void main() {
  test(
    'reads numbers as they arrive',
    () => runTest((it) async {
      final ByteChannel channel = _arriving(it, [
        [0xFF, 0x12],
        [0x34, 0, 0, 0],
        [1, 0, 0, 0, 0, 0, 0, 0, 2, 0x3F, 0xC0, 0, 0],
        [0x40, 0, 0, 0, 0, 0, 0, 0],
      ]);

      expect(await channel.readByte(), 0xFF);
      expect(await channel.readShort(), 0x1234);
      expect(await channel.readInt(), 1);
      expect(await channel.readLong(), 2);
      expect(await channel.readFloat(), 1.5);
      expect(await channel.readDouble(), 2);
      expect(await channel.exhausted(), isTrue);
    }),
  );

  test('reads little-endian numbers', () async {
    final channel = ByteReadChannel.fromBytes([
      2,
      1,
      4,
      3,
      2,
      1,
      1,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0xC0,
      0x3F,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0x40,
    ]);

    expect(await channel.readShort(endian: Endian.little), 0x0102);
    expect(await channel.readInt(endian: Endian.little), 0x01020304);
    expect(await channel.readLong(endian: Endian.little), 1);
    expect(await channel.readFloat(endian: Endian.little), 1.5);
    expect(await channel.readDouble(endian: Endian.little), 2);
  });

  test('fails to read a number the channel ends before', () async {
    await expectLater(
      ByteReadChannel.fromBytes([1]).readShort(),
      throwsA(isA<EofException>()),
    );
    await expectLater(
      ByteReadChannel.empty.readByte(),
      throwsA(isA<EofException>()),
    );
  });

  test(
    'reads everything that is left, or up to a maximum',
    () => runTest((it) async {
      final ByteChannel channel = _arriving(it, [
        [1, 2],
        [3, 4, 5],
      ]);

      final Buffer first = await channel.readRemaining(3);
      final Buffer rest = await channel.readRemaining();

      expect(first.readBytes(), [1, 2, 3]);
      expect(rest.readBytes(), [4, 5]);
    }),
  );

  test('fails to read the rest of a cancelled channel', () async {
    final channel = ByteChannel()..cancel(const EofException('gone'));

    await expectLater(
      channel.readRemaining(),
      throwsA(isA<ClosedByteChannelException>()),
    );
  });

  test(
    'reads an exact number of bytes',
    () => runTest((it) async {
      final ByteChannel channel = _arriving(it, [
        [1],
        [2, 3],
        [4],
      ]);

      final Uint8List three = await channel.readBytes(3);

      expect(three, [1, 2, 3]);
      await expectLater(
        channel.readPacket(2),
        throwsA(
          isA<EofException>().having(
            (error) => error.message,
            'message',
            'Not enough data available, required 2 bytes but only 1 available',
          ),
        ),
      );
      expect(() => channel.readPacket(-1), throwsRangeError);
    }),
  );

  test(
    'reads what has arrived into a list',
    () => runTest((it) async {
      final ByteChannel channel = _arriving(it, [
        [1, 2],
        [3],
      ]);
      final destination = Uint8List(4);

      final int first = await channel.readAvailable(destination);
      final int second = await channel.readAvailable(destination, 2, 1);
      final int end = await channel.readAvailable(destination);

      expect(first, 2);
      expect(second, 1);
      expect(end, -1);
      expect(destination, [1, 2, 3, 0]);
      expect(await ByteReadChannel.empty.readAvailable(destination), -1);
    }),
  );

  test(
    'reports the end to a reader that waited for it',
    () => runTest((it) async {
      final channel = ByteChannel();
      it.launch((it) async {
        await yieldNow();
        channel.close();
      });

      expect(await channel.readAvailable(Uint8List(1)), -1);
    }),
  );

  test(
    'fills a list completely or fails',
    () => runTest((it) async {
      final ByteChannel channel = _arriving(it, [
        [1],
        [2, 3],
      ]);
      final destination = Uint8List(4);

      await channel.readFully(destination, 1, 3);
      await expectLater(
        channel.readFully(destination),
        throwsA(isA<EofException>()),
      );
      expect(destination, [3, 1, 2, 0]);
      await expectLater(
        ByteReadChannel.empty.readFully(Uint8List(1)),
        throwsA(isA<EofException>()),
      );
      await ByteReadChannel.empty.readFully(Uint8List(0));
    }),
  );

  test(
    'drops bytes, up to what is there',
    () => runTest((it) async {
      final ByteChannel channel = _arriving(it, [
        [1, 2],
        [3, 4],
      ]);

      final int dropped = await channel.discard(3);
      final int rest = await channel.discard();

      expect(dropped, 3);
      expect(rest, 1);
      await expectLater(
        ByteReadChannel.fromBytes([1]).discardExact(2),
        throwsA(isA<EofException>()),
      );
      await ByteReadChannel.fromBytes([1, 2]).discardExact(2);
    }),
  );

  test(
    'copies to a writer, up to a limit',
    () => runTest((it) async {
      final ByteChannel source = _arriving(it, [
        [1, 2],
        [3, 4],
      ]);
      final target = ByteChannel();

      final int first = await source.copyTo(target, limit: 3);
      final int rest = await source.copyAndClose(target);

      expect(first, 3);
      expect(rest, 1);
      expect(await target.toBytes(), [1, 2, 3, 4]);
      expect(target.isClosedForRead, isTrue);
    }),
  );

  test('cancels both channels when a copy fails', () async {
    final source = ByteChannel()..cancel(const EofException('source gone'));
    final target = ByteChannel();

    await expectLater(
      source.copyTo(target),
      throwsA(isA<ClosedByteChannelException>()),
    );
    expect(target.closedCause, isA<ClosedByteChannelException>());
  });

  test('peeks and skips what comes next', () async {
    final channel = ByteReadChannel.fromBytes([1, 2, 3]);

    final ByteString? peeked = await channel.peek(2);
    final bool skipped = await channel.skipIfFound(ByteString(const [1, 2]));
    final bool notSkipped = await channel.skipIfFound(ByteString(const [4]));

    expect(peeked, ByteString(const [1, 2]));
    expect(skipped, isTrue);
    expect(notSkipped, isFalse);
    expect(await channel.peek(2), isNull);
    expect(await channel.readByte(), 3);
    expect(await channel.peek(1), isNull);
  });

  test('rethrows the cause of a failed channel on request', () {
    final channel = ByteChannel()
      ..rethrowCloseCauseIfNeeded()
      ..cancel(const EofException('gone'));

    expect(
      channel.rethrowCloseCauseIfNeeded,
      throwsA(isA<ClosedByteChannelException>()),
    );
  });
}
