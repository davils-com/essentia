/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:typed_data';

import 'package:essentia_io/src/channel/byte_read_channel.dart';
import 'package:essentia_io/src/stream/internal/channel_stream.dart';

/// Reads a [ByteReadChannel] as a Dart stream.
extension ByteReadChannelStreams on ByteReadChannel {
  /// The bytes of the channel as a stream of chunks, as they arrive.
  ///
  /// The stream reads while it is listened to and not paused, ends with the
  /// channel and fails with its [ByteReadChannel.closedCause]. A listener
  /// that cancels its subscription before the end cancels the channel.
  ///
  /// Returns the stream, which may be listened to once.
  Stream<Uint8List> toStream() => ChannelStream(this).stream;
}
