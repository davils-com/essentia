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

import 'package:essentia_io/src/channel/byte_channel.dart';
import 'package:meta/meta.dart';

/// A channel that reads the chunks of [stream] as they come, pausing the
/// subscription while the channel is full.
///
/// The channel closes when the stream is done and is cancelled with the
/// error of the stream; cancelling the channel cancels the subscription.
///
/// Returns the channel.
@internal
ByteChannel streamByteReadChannel(Stream<List<int>> stream) {
  final channel = ByteChannel();
  final StreamSubscription<List<int>> subscription = stream.listen(
    null,
    onError: (Object error, StackTrace stackTrace) => channel.cancel(error),
    onDone: channel.close,
    cancelOnError: true,
  );
  subscription.onData((chunk) {
    if (channel.isClosedForWrite) {
      return;
    }
    channel.writeBuffer.write(chunk);
    channel.flushWriteBuffer();
    if (channel.hasFreeSpace) {
      return;
    }
    subscription.pause();
    unawaited(
      channel.flush().then(
        (_) => subscription.resume(),
        onError: (Object error) => subscription.resume(),
      ),
    );
  });
  channel.invokeOnClose((cause) {
    if (cause != null) {
      unawaited(subscription.cancel());
    }
  });
  return channel;
}
