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

import 'dart:convert';

import 'package:essentia_core/essentia_core.dart';
import 'package:essentia_io/src/buffer/buffer.dart';
import 'package:essentia_io/src/channel/internal/buffer_byte_read_channel.dart';
import 'package:essentia_io/src/channel/internal/empty_byte_read_channel.dart';
import 'package:essentia_io/src/stream/stream_byte_read_channel.dart';

/// A channel bytes are read from as they arrive.
///
/// A reader waits with [awaitContent] until bytes are there, and then
/// takes them from [readBuffer]; the operations of
/// `ByteReadChannelOperations`, such as `readInt`, `readLine` and
/// `readUntil`, do both. A channel has one reader at a time.
///
/// A channel ends when its writer closes it and its bytes are read, or
/// when either side cancels it; [closedCause] then says why.
///
/// ```dart
/// final channel = ByteReadChannel.fromText('first\nsecond\n');
/// final String? line = await channel.readLine();
/// ```
abstract interface class ByteReadChannel {
  /// Creates a channel that holds the bytes of [content] from [start] to
  /// [end], the end by default, and is closed behind them.
  ///
  /// Throws a [RangeError] when [start] and [end] are not a range of
  /// [content].
  factory ByteReadChannel.fromBytes(
    List<int> content, [
    int start = 0,
    int? end,
  ]) => BufferByteReadChannel(Buffer()..write(content, start, end));

  /// Creates a channel that holds [text] in [charset] and is closed behind
  /// it.
  ///
  /// Throws an [ArgumentError] for a character [charset] cannot represent.
  factory ByteReadChannel.fromText(
    String text, {
    Encoding charset = Charsets.utf8,
  }) => BufferByteReadChannel(Buffer()..write(charset.encode(text)));

  /// Creates a channel that reads the bytes of [source], taking them over,
  /// and is closed behind them.
  factory ByteReadChannel.fromBuffer(Buffer source) =>
      BufferByteReadChannel(source);

  /// Creates a channel that reads the chunks of [stream] as they come, and
  /// pauses the stream while the channel is full.
  ///
  /// The channel ends with the stream, and fails with its error. Cancelling
  /// the channel cancels the subscription.
  factory ByteReadChannel.fromStream(Stream<List<int>> stream) =>
      streamByteReadChannel(stream);

  /// A channel without bytes that is closed.
  static final ByteReadChannel empty = EmptyByteReadChannel();

  /// Why the channel failed: a cancellation, or the failure it was
  /// cancelled with, wrapped as a `ClosedByteChannelException`; `null`
  /// while it is open and once it was closed normally.
  Exception? get closedCause;

  /// Whether nothing more can be read: every byte is read and the writer
  /// closed the channel, or the channel failed.
  bool get isClosedForRead;

  /// The bytes that arrived and are not read yet, which the operations take
  /// from.
  ///
  /// Throws a `ClosedReadChannelException` once the channel failed.
  Buffer get readBuffer;

  /// Waits until [readBuffer] holds at least [min] bytes, or the channel
  /// ends.
  ///
  /// Returns `true` when it holds them, `false` when the channel ended
  /// before.
  ///
  /// Throws [closedCause] once the channel failed.
  Future<bool> awaitContent([int min = 1]);

  /// Cancels the channel with [cause], an `IoException` saying it was
  /// cancelled by default: the bytes not read are dropped, and the writer
  /// fails with it.
  void cancel([Object? cause]);
}
