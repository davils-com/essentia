/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:essentia_io/src/channel/byte_read_channel.dart';
import 'package:essentia_io/src/job/channel_job.dart';

/// A writer coroutine and the channel it writes, Ktor's `WriterJob`:
/// [channel] is the side to read what it writes.
final class WriterJob implements ChannelJob {
  /// Creates the writer of [job] that writes into [channel].
  WriterJob(this.channel, this.job);

  /// The channel to read what the coroutine writes.
  final ByteReadChannel channel;

  /// The job of the coroutine.
  @override
  final Job job;
}
