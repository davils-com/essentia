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

import 'package:essentia_core/essentia_core.dart';
import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:essentia_coroutines/testing.dart';
import 'package:essentia_io/essentia_io.dart';
import 'package:test/test.dart';

/// Covers the channels of bytes that are complete, the empty channel and
/// the channels that count.
void main() {
  test('reads the bytes of a list, a range of one and a text', () async {
    final bytes = ByteReadChannel.fromBytes([1, 2, 3]);
    final range = ByteReadChannel.fromBytes([1, 2, 3], 1, 2);
    final text = ByteReadChannel.fromText('é', charset: Charsets.iso88591);

    expect(await bytes.toBytes(), [1, 2, 3]);
    expect(await range.toBytes(), [2]);
    expect(await text.toBytes(), [0xE9]);
    expect(bytes.isClosedForRead, isTrue);
  });

  test('reads a buffer it takes over', () async {
    final buffer = Buffer()..write([4, 5]);
    final channel = ByteReadChannel.fromBuffer(buffer);

    final bool two = await channel.awaitContent(2);
    final bool three = await channel.awaitContent(3);

    expect(two, isTrue);
    expect(three, isFalse);
    expect(channel.closedCause, isNull);
    expect(await channel.readShort(), 0x0405);
  });

  test('fails once a channel of complete bytes was cancelled', () async {
    final channel = ByteReadChannel.fromBytes([1, 2])..cancel();

    expect(channel.isClosedForRead, isTrue);
    expect(channel.closedCause, isA<ClosedByteChannelException>());
    expect(
      () => channel.readBuffer,
      throwsA(isA<ClosedByteChannelException>()),
    );
    await expectLater(
      channel.awaitContent(),
      throwsA(isA<ClosedByteChannelException>()),
    );
    channel.cancel(const EofException('again'));
    expect(
      (channel.closedCause! as ClosedByteChannelException).message,
      'Channel was cancelled',
    );
  });

  test('has nothing in the empty channel', () async {
    final ByteReadChannel channel = ByteReadChannel.empty;
    channel.readBuffer.write([1]);

    expect(channel.isClosedForRead, isTrue);
    expect(channel.closedCause, isNull);
    expect(channel.readBuffer.exhausted, isTrue);
    expect(await channel.awaitContent(), isFalse);
    channel.cancel();
    expect(await channel.readLine(), isNull);
  });

  test('counts the bytes read through a channel', () async {
    final CountedByteReadChannel counted = ByteReadChannel.fromBytes([
      1,
      2,
      3,
      4,
      5,
    ]).asCountedReadChannel();

    final int first = await counted.readByte();
    final int beforeMore = counted.totalBytesRead;
    await counted.discard(2);

    expect(first, 1);
    expect(beforeMore, 1);
    expect(counted.totalBytesRead, 3);
    expect(counted.isClosedForRead, isFalse);
    expect(await counted.toBytes(), [4, 5]);
    expect(counted.totalBytesRead, 5);
    expect(counted.isClosedForRead, isTrue);
    expect(counted.closedCause, isNull);
  });

  test('waits through a counting channel and cancels its source', () async {
    final source = ByteChannel();
    final CountedByteReadChannel counted = source.asCountedReadChannel();
    source.writeBuffer.write([1, 2]);
    await source.flush();

    final bool two = await counted.awaitContent(2);
    source.close();
    final bool three = await counted.awaitContent(3);
    counted.cancel(const EofException('done'));

    expect(two, isTrue);
    expect(three, isFalse);
    expect(source.isClosedForWrite, isTrue);
    expect(counted.delegate, same(source));
  });

  test(
    'waits through a counting channel for bytes still to come',
    () => runTest((it) async {
      final source = ByteChannel();
      final CountedByteReadChannel counted = source.asCountedReadChannel();
      final Deferred<bool> waiting = it.async((it) => counted.awaitContent(2));
      it.runCurrent();

      await source.writeFully([1, 2]);
      await source.flush();

      expect(await waiting, isTrue);
      expect(counted.availableForRead, 2);
    }),
  );

  test('counts the bytes written through a channel', () async {
    final target = ByteChannel();
    final CountedByteWriteChannel counted = target.asCountedWriteChannel();

    await counted.writeFully([1, 2, 3]);
    final int unflushed = counted.totalBytesWritten;
    await counted.flush();
    await counted.writeByte(4);

    expect(unflushed, 3);
    expect(counted.totalBytesWritten, 4);
    expect(counted.autoFlush, isFalse);
    expect(counted.isClosedForWrite, isFalse);
    expect(counted.closedCause, isNull);
    await counted.flushAndClose();
    expect(await target.toBytes(), [1, 2, 3, 4]);
  });

  test('cancels the target of a counting writer', () {
    final target = ByteChannel();

    target.asCountedWriteChannel().cancel(const EofException('stop'));

    expect(target.closedCause, isA<ClosedByteChannelException>());
  });

  test('counts from nothing on a closed target', () {
    final target = ByteChannel()..close();

    expect(target.asCountedWriteChannel().isClosedForWrite, isTrue);
  });
}
