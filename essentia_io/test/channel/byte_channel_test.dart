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

import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:essentia_coroutines/testing.dart';
import 'package:essentia_io/essentia_io.dart';
import 'package:test/test.dart';

import '../support/outcome.dart';

/// Covers `ByteChannel`: flushing to the reader, waiting, back pressure,
/// closing, cancelling and one reader and one writer at a time.
void main() {
  test('hands flushed bytes to the reader', () async {
    final channel = ByteChannel();
    channel.writeBuffer.write([1, 2, 3]);

    final bool before = channel.readBuffer.exhausted;
    await channel.flush();
    final bool content = await channel.awaitContent(3);

    expect(before, isTrue);
    expect(content, isTrue);
    expect(channel.readBuffer.readBytes(), [1, 2, 3]);
  });

  test(
    'wakes a waiting reader when the writer flushes',
    () => runTest((it) async {
      final channel = ByteChannel();
      final Deferred<bool> waiting = it.async((it) => channel.awaitContent(2));
      it.runCurrent();

      channel.writeBuffer.writeByte(1);
      await channel.flush();
      it.runCurrent();
      final bool stillWaiting = waiting.isActive;
      channel.writeBuffer.writeByte(2);
      await channel.flush();

      expect(stillWaiting, isTrue);
      expect(await waiting, isTrue);
      expect(channel.availableForRead, 2);
    }),
  );

  test(
    'lets the writer wait while the reader is a full channel behind',
    () => runTest((it) {
      final channel = ByteChannel();
      channel.writeBuffer.write(List<int>.filled(ByteChannel.maxSize, 1));
      final Job writing = it.launch((it) => channel.flush());
      it.runCurrent();

      final bool waited = writing.isActive;
      final int read = channel.readBuffer.size;
      it.runCurrent();

      expect(waited, isTrue);
      expect(channel.hasFreeSpace, isTrue);
      expect(read, ByteChannel.maxSize);
      expect(writing.isCompleted, isTrue);
    }),
  );

  test(
    'feeds a reader that waits for a whole channel of bytes',
    () => runTest((it) async {
      final channel = ByteChannel();
      final Deferred<bool> reading = it.async(
        (it) => channel.awaitContent(ByteChannel.maxSize),
      );
      final Job writing = it.launch((it) async {
        channel.writeBuffer.write(List<int>.filled(ByteChannel.maxSize * 2, 7));
        await channel.flush();
      });

      final bool content = await reading;
      channel.readBuffer.discard(ByteChannel.maxSize * 2);
      await writing.join();

      expect(content, isTrue);
    }),
  );

  test('flushes every write with auto flush', () async {
    final channel = ByteChannel(autoFlush: true);

    await channel.writeByte(5);

    expect(channel.autoFlush, isTrue);
    expect(channel.availableForRead, 1);
  });

  test('ends for the reader once closed and read', () async {
    final channel = ByteChannel();
    channel.writeBuffer.write([1]);
    channel.close();

    final bool openBefore = channel.isClosedForRead;
    final int byte = channel.readBuffer.readByte();

    expect(openBefore, isFalse);
    expect(byte, 1);
    expect(channel.isClosedForRead, isTrue);
    expect(channel.isClosedForWrite, isTrue);
    expect(channel.closedCause, isNull);
    expect(await channel.awaitContent(), isFalse);
  });

  test(
    'wakes a waiting reader with the end when closed',
    () => runTest((it) async {
      final channel = ByteChannel();
      final Deferred<bool> waiting = it.async((it) => channel.awaitContent());
      it.runCurrent();

      await channel.flushAndClose();

      expect(await waiting, isFalse);
    }),
  );

  test('refuses writes once closed', () async {
    final channel = ByteChannel()..close();

    expect(
      () => channel.writeBuffer,
      throwsA(isA<ClosedWriteChannelException>()),
    );
    await channel.flushAndClose();
    channel.close();
  });

  test('fails both sides with the cause it was cancelled with', () async {
    final channel = ByteChannel()..writeBuffer.write([1]);
    const cause = EofException('peer gone');

    channel.cancel(cause);

    final Exception? closed = channel.closedCause;
    expect(closed, isA<ClosedByteChannelException>());
    expect((closed! as ClosedByteChannelException).cause, same(cause));
    expect(channel.isClosedForRead, isTrue);
    expect(
      () => channel.readBuffer,
      throwsA(isA<ClosedReadChannelException>()),
    );
    expect(
      () => channel.writeBuffer,
      throwsA(isA<ClosedWriteChannelException>()),
    );
    await expectLater(
      channel.awaitContent(),
      throwsA(isA<ClosedByteChannelException>()),
    );
    await expectLater(
      channel.flush(),
      throwsA(isA<ClosedByteChannelException>()),
    );
  });

  test('says it was cancelled when no cause is given', () {
    final channel = ByteChannel()..cancel();

    expect(
      (channel.closedCause! as ClosedByteChannelException).message,
      'Channel was cancelled',
    );
  });

  test('passes a cancellation on as a cancellation of its own', () {
    const cause = CancellationException('stopped');
    final channel = ByteChannel()..cancel(cause);

    final Exception? closed = channel.closedCause;

    expect(closed, isA<CancellationException>());
    expect((closed! as CancellationException).cause, same(cause));
    expect(closed, isNot(same(cause)));
  });

  test(
    'wakes a waiting reader with the cause when cancelled',
    () => runTest((it) async {
      final channel = ByteChannel();
      final Deferred<Object?> waiting = it.async(
        (it) => failureOf(channel.awaitContent),
      );
      it.runCurrent();

      channel.cancel(const EofException('gone'));

      expect(await waiting, isA<ClosedByteChannelException>());
    }),
  );

  test(
    'fails a waiter that comes after the end with its cause',
    () => runTest((it) async {
      final channel = ByteChannel()..cancel(const EofException('gone'));

      await expectLater(
        channel.flush(),
        throwsA(isA<ClosedByteChannelException>()),
      );
    }),
  );

  test('stays as it is when closed or cancelled again', () {
    final channel = ByteChannel()
      ..close()
      ..cancel(const EofException('late'));

    expect(channel.closedCause, isNull);
  });

  test(
    'closes after a flush that fails because it was cancelled',
    () => runTest((it) async {
      final channel = ByteChannel();
      channel.writeBuffer.write(List<int>.filled(ByteChannel.maxSize, 1));
      final Job closing = it.launch((it) => channel.flushAndClose());
      it.runCurrent();

      channel.cancel(const EofException('gone'));
      await closing.join();

      expect(closing.isCancelled, isFalse);
      expect(channel.closedCause, isA<ClosedByteChannelException>());
    }),
  );

  test(
    'refuses a second reader waiting at the same time',
    () => runTest((it) async {
      final channel = ByteChannel();
      final Deferred<Object?> first = it.async(
        (it) => failureOf(channel.awaitContent),
      );
      it.runCurrent();
      final Deferred<bool> second = it.async((it) => channel.awaitContent());
      it.runCurrent();

      channel.writeBuffer.writeByte(1);
      await channel.flush();

      expect(await first, isA<ConcurrentIoException>());
      expect(await second, isTrue);
    }),
  );

  test(
    'forgets a reader whose job was cancelled',
    () => runTest((it) async {
      final channel = ByteChannel();
      final Deferred<bool> waiting = it.async((it) => channel.awaitContent());
      it.runCurrent();

      await waiting.cancelAndJoin();
      final Deferred<bool> next = it.async((it) => channel.awaitContent());
      it.runCurrent();
      channel.writeBuffer.writeByte(1);
      await channel.flush();

      expect(await next, isTrue);
    }),
  );

  test('refuses to wait for no byte or more than a channel holds', () async {
    final channel = ByteChannel();

    await expectLater(channel.awaitContent(0), throwsRangeError);
    await expectLater(
      channel.awaitContent(ByteChannel.maxSize + 1),
      throwsRangeError,
    );
  });

  test('runs its close handler once closed, or at once', () {
    final causes = <Object?>[];
    final channel = ByteChannel()..invokeOnClose(causes.add);

    expect(() => channel.invokeOnClose(causes.add), throwsStateError);
    channel
      ..cancel(const EofException('gone'))
      ..invokeOnClose(causes.add);

    expect(causes, hasLength(2));
    expect(causes, everyElement(isA<ClosedByteChannelException>()));
  });

  test('describes itself without its bytes', () {
    expect(ByteChannel().toString(), startsWith('ByteChannel['));
  });
}
