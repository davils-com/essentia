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

import 'dart:async';
import 'dart:typed_data';

import 'package:essentia_coroutines/testing.dart';
import 'package:essentia_io/essentia_io.dart';
import 'package:test/test.dart';

/// Covers the bridges between channels and Dart's streams.
void main() {
  test('reads the chunks of a stream', () async {
    final channel = ByteReadChannel.fromStream(
      Stream<List<int>>.fromIterable([
        [1, 2],
        [3],
      ]),
    );

    final Uint8List bytes = await channel.toBytes();

    expect(bytes, [1, 2, 3]);
    expect(channel.isClosedForRead, isTrue);
  });

  test('pauses a stream while the channel is full', () async {
    var pauses = 0;
    final controller = StreamController<List<int>>(onPause: () => pauses++);
    final channel = ByteReadChannel.fromStream(controller.stream);
    controller.add(Uint8List(ByteChannel.maxSize));
    await Future<void>.delayed(Duration.zero);

    final bool paused = controller.isPaused;
    await channel.discard(ByteChannel.maxSize);
    await Future<void>.delayed(Duration.zero);
    controller.add([1]);
    unawaited(controller.close());

    expect(paused, isTrue);
    expect(pauses, 1);
    expect(controller.isPaused, isFalse);
    expect(await channel.toBytes(), [1]);
  });

  test('resumes a paused stream once the channel is cancelled', () async {
    final controller = StreamController<List<int>>();
    var cancelled = false;
    controller.onCancel = () => cancelled = true;
    final channel = ByteReadChannel.fromStream(controller.stream);
    controller.add(Uint8List(ByteChannel.maxSize));
    await Future<void>.delayed(Duration.zero);

    channel.cancel(const EofException('reader gone'));
    await Future<void>.delayed(Duration.zero);
    await controller.close();

    expect(cancelled, isTrue);
  });

  test('fails the channel with the error of the stream', () async {
    final channel = ByteReadChannel.fromStream(
      Stream<List<int>>.error(StateError('disk gone')),
    );

    await expectLater(
      channel.toBytes(),
      throwsA(isA<ClosedByteChannelException>()),
    );
  });

  test('ignores chunks after the channel was cancelled', () async {
    final controller = StreamController<List<int>>(sync: true);
    final channel = ByteReadChannel.fromStream(controller.stream);
    final inner = channel as ByteChannel..cancel();

    controller.add([1]);

    expect(inner.isClosedForWrite, isTrue);
    await controller.close();
  });

  test(
    'hands out the bytes of a channel as a stream',
    () => runTest((it) async {
      final WriterJob writing = it.writer((it) async {
        await it.channel.writeFully([1, 2]);
        await it.channel.flush();
        await it.channel.writeFully([3]);
      });

      final List<Uint8List> chunks = await writing.channel.toStream().toList();

      expect([for (final Uint8List chunk in chunks) ...chunk], [1, 2, 3]);
    }),
  );

  test('fails the stream with the cause of the channel', () async {
    final channel = ByteChannel()..cancel(const EofException('gone'));

    await expectLater(
      channel.toStream().toList(),
      throwsA(isA<ClosedByteChannelException>()),
    );
  });

  test('cancels the channel when the stream is cancelled', () async {
    final channel = ByteChannel()..writeBuffer.write([1]);
    await channel.flush();

    final StreamSubscription<Uint8List> subscription = channel
        .toStream()
        .listen(null);
    await Future<void>.delayed(Duration.zero);
    await subscription.cancel();

    expect(channel.closedCause, isA<ClosedByteChannelException>());
  });

  test('holds the reading back while the listener is paused', () async {
    final channel = ByteChannel();
    final received = <int>[];
    final StreamSubscription<Uint8List> subscription = channel
        .toStream()
        .listen(received.addAll);
    await channel.writeFully([1]);
    await channel.flush();
    await Future<void>.delayed(Duration.zero);

    subscription.pause();
    await channel.writeFully([2]);
    await channel.flush();
    await Future<void>.delayed(Duration.zero);
    final List<int> whilePaused = List.of(received);
    subscription.resume();
    await channel.flushAndClose();
    await subscription.asFuture<void>();
    await subscription.cancel();

    expect(whilePaused, [1]);
    expect(received, [1, 2]);
  });

  test('fails the stream when the channel fails while it waits', () async {
    final channel = ByteChannel();
    final Future<List<Uint8List>> chunks = channel.toStream().toList();
    await Future<void>.delayed(Duration.zero);

    channel.cancel(const EofException('writer gone'));

    await expectLater(chunks, throwsA(isA<ClosedByteChannelException>()));
  });
}
