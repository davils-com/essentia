/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:essentia_io/src/channel/byte_channel.dart';
import 'package:essentia_io/src/job/reader_job.dart';
import 'package:essentia_io/src/job/reader_scope.dart';
import 'package:essentia_io/src/job/writer_job.dart';
import 'package:essentia_io/src/job/writer_scope.dart';

/// `writer` and `reader`: coroutines that write or read one side of a
/// byte channel, whose other side the caller gets.
extension CoroutineScopeByteChannels on CoroutineScope {
  /// Starts [block] as a child coroutine that writes to a channel, by
  /// default a new [ByteChannel] with [autoFlush], and hands out the side
  /// to read.
  ///
  /// The channel is flushed and closed when [block] completes, and
  /// cancelled with what [block] failed with; the failure does not fail
  /// the scope, the reader sees it. Cancelling the coroutine cancels the
  /// channel.
  ///
  /// ```dart
  /// final WriterJob writing = scope.writer((it) async {
  ///   await it.channel.writeString('hello');
  /// });
  /// final String? text = await writing.channel.readLine();
  /// ```
  ///
  /// Returns the job and the channel to read.
  WriterJob writer(
    FutureOr<void> Function(WriterScope it) block, {
    CoroutineContext context = CoroutineContext.empty,
    bool autoFlush = false,
    ByteChannel? channel,
  }) {
    final ByteChannel target = channel ?? ByteChannel(autoFlush: autoFlush);
    final Job job =
        launch((it) async {
          try {
            await block(WriterScope(target, it.coroutineContext));
            if (it.coroutineContext.job.isCancelled) {
              target.cancel(it.coroutineContext.job.getCancellationException());
            }
          } on Object catch (error) {
            target.cancel(error);
          } finally {
            await target.flushAndClose();
          }
        }, context: context)..invokeOnCompletion((cause) {
          if (cause != null && !target.isClosedForWrite) {
            target.cancel(cause);
          }
        });
    return WriterJob(target, job);
  }

  /// Starts [block] as a child coroutine that reads from a channel, by
  /// default a new [ByteChannel] with [autoFlush], and hands out the side
  /// to write.
  ///
  /// The channel is cancelled with what [block] failed with, or with the
  /// cancellation of the coroutine; the failure does not fail the scope,
  /// the writer sees it.
  ///
  /// Returns the job and the channel to write.
  ReaderJob reader(
    FutureOr<void> Function(ReaderScope it) block, {
    CoroutineContext context = CoroutineContext.empty,
    bool autoFlush = false,
    ByteChannel? channel,
  }) {
    final ByteChannel target = channel ?? ByteChannel(autoFlush: autoFlush);
    final Job job =
        launch((it) async {
          try {
            await block(ReaderScope(target, it.coroutineContext));
            if (it.coroutineContext.job.isCancelled) {
              target.cancel(it.coroutineContext.job.getCancellationException());
            }
          } on Object catch (error) {
            target.cancel(error);
          }
        }, context: context)..invokeOnCompletion((cause) {
          if (cause != null && !target.isClosedForRead) {
            target.cancel(cause);
          }
        });
    return ReaderJob(target, job);
  }
}
