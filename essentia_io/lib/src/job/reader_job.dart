/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:essentia_io/src/channel/byte_write_channel.dart';
import 'package:essentia_io/src/job/channel_job.dart';

/// A reader coroutine and the channel it reads, Ktor's `ReaderJob`:
/// [channel] is the side to write what it reads.
final class ReaderJob implements ChannelJob {
  /// Creates the reader of [job] that reads from [channel].
  ReaderJob(this.channel, this.job);

  /// The channel to write what the coroutine reads.
  final ByteWriteChannel channel;

  /// The job of the coroutine.
  @override
  final Job job;
}
