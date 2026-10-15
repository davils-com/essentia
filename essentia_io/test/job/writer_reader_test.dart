/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';
import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:essentia_coroutines/testing.dart';
import 'package:essentia_io/essentia_io.dart';
import 'package:test/test.dart';

/// Covers the writer and reader coroutines of a channel.
void main() {
  test(
    'hands out what a writer wrote and closes the channel',
    () => runTest((it) async {
      final WriterJob writing = it.writer((it) async {
        await it.channel.writeString('hello\nworld');
      });

      final String? first = await writing.channel.readLine();
      final String? second = await writing.channel.readLine();
      await writing.join();

      expect(first, 'hello');
      expect(second, 'world');
      expect(writing.isCompleted, isTrue);
      expect(writing.isCancelled, isFalse);
      expect(writing.channel.isClosedForRead, isTrue);
    }),
  );

  test(
    'flushes every write of a writer with auto flush',
    () => runTest((it) async {
      final WriterJob writing = it.writer((it) async {
        await it.channel.writeByte(1);
        await awaitCancellation();
      }, autoFlush: true);
      it.runCurrent();

      final int available = writing.channel.availableForRead;
      writing.cancel();
      await writing.join();

      expect(available, 1);
    }),
  );

  test(
    'fails the reader, not the scope, with what the writer failed with',
    () => runTest((it) async {
      final WriterJob writing = it.writer((it) async {
        await it.channel.writeByte(1);
        throw const EofException('source gone');
      });

      await writing.join();

      expect(writing.isCancelled, isFalse);
      expect(writing.channel.closedCause, isA<ClosedByteChannelException>());
    }),
  );

  test(
    'cancels the channel when the writer is cancelled',
    () => runTest((it) async {
      final WriterJob writing = it.writer((it) => awaitCancellation());
      it.runCurrent();
      final causes = <Object?>[];
      final Disposable handle = writing.invokeOnCompletion(causes.add);

      writing.cancel();
      await writing.join();

      expect(writing.channel.closedCause, isA<CancellationException>());
      expect(writing.getCancellationException(), isA<CancellationException>());
      expect(causes, [isA<CancellationException>()]);
      handle.dispose();
    }),
  );

  test(
    'cancels the channel when the writer ends in a cancelled job',
    () => runTest((it) async {
      final WriterJob writing = it.writer((it) {
        it.coroutineContext.job.cancel();
      });

      await writing.join();

      expect(writing.channel.closedCause, isA<CancellationException>());
    }),
  );

  test(
    'writes into a channel it is given',
    () => runTest((it) async {
      final channel = ByteChannel();

      final WriterJob writing = it.writer(
        (it) => it.channel.writeByte(7),
        channel: channel,
      );
      await writing.join();

      expect(writing.channel, same(channel));
      expect(await channel.readByte(), 7);
    }),
  );

  test(
    'reads what is written to a reader',
    () => runTest((it) async {
      final received = <String?>[];
      final ReaderJob reading = it.reader((it) async {
        received.add(await it.channel.readLine());
      });

      await reading.channel.writeString('line\n');
      await reading.channel.flush();
      await reading.join();

      expect(received, ['line']);
      expect(reading.isCompleted, isTrue);
    }),
  );

  test(
    'fails the writer with what the reader failed with',
    () => runTest((it) async {
      final ReaderJob reading = it.reader((it) async {
        await it.channel.readByte();
        throw const EofException('parse error');
      }, autoFlush: true);

      await reading.channel.writeByte(1);
      await reading.join();

      expect(reading.channel.isClosedForWrite, isTrue);
      expect(reading.channel.closedCause, isA<ClosedByteChannelException>());
    }),
  );

  test(
    'cancels the channel when the reader is cancelled',
    () => runTest((it) async {
      final ReaderJob reading = it.reader((it) => awaitCancellation());
      it.runCurrent();

      reading.cancel();
      await reading.join();

      expect(reading.channel.closedCause, isA<CancellationException>());
    }),
  );

  test(
    'cancels the channel when the reader ends in a cancelled job',
    () => runTest((it) async {
      final channel = ByteChannel();

      final ReaderJob reading = it.reader((it) {
        it.coroutineContext.job.cancel();
      }, channel: channel);
      await reading.join();

      expect(channel.closedCause, isA<CancellationException>());
    }),
  );

  test(
    'cancels the channel of a writer cancelled before it ran',
    () => runTest((it) async {
      final WriterJob writing = it.writer((it) => it.channel.writeByte(1))
        ..cancel();

      await writing.join();

      expect(writing.channel.closedCause, isA<CancellationException>());
    }),
  );

  test(
    'cancels the channel of a reader cancelled before it ran',
    () => runTest((it) async {
      final ReaderJob reading = it.reader((it) => it.channel.readByte())
        ..cancel();

      await reading.join();

      expect(reading.channel.isClosedForWrite, isTrue);
      expect(reading.channel.closedCause, isA<CancellationException>());
    }),
  );
}
