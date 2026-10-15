/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
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
