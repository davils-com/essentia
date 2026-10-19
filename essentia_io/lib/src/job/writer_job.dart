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
import 'package:essentia_io/src/channel/byte_read_channel.dart';
import 'package:essentia_io/src/job/channel_job.dart';

/// A writer coroutine and the channel it writes:
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
