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

import 'package:essentia_io/src/buffer/buffer.dart';

/// A channel bytes are written to for a reader.
///
/// A writer puts bytes into [writeBuffer] and hands them to the reader with
/// [flush], which waits while the reader is too far behind; the operations
/// of `ByteWriteChannelOperations`, such as `writeInt` and `writeFully`,
/// do both. With [autoFlush] every operation flushes. A channel has one
/// writer at a time.
///
/// ```dart
/// final channel = ByteChannel();
/// await channel.writeString('hello');
/// await channel.flushAndClose();
/// ```
abstract interface class ByteWriteChannel {
  /// Whether every write operation flushes at once.
  bool get autoFlush;

  /// Whether nothing more can be written: the channel was closed or
  /// cancelled.
  bool get isClosedForWrite;

  /// Why the channel failed, as the read side reports it; `null` while it
  /// is open and once it was closed normally.
  Exception? get closedCause;

  /// The bytes written and not flushed yet.
  ///
  /// Throws a `ClosedWriteChannelException` once the channel is closed.
  Buffer get writeBuffer;

  /// Hands the written bytes to the reader, and waits while the reader has
  /// more than the channel holds before it waits for the reader.
  ///
  /// Throws [closedCause] once the channel failed.
  Future<void> flush();

  /// Flushes and closes the channel: the reader reads what was written and
  /// then sees the end.
  Future<void> flushAndClose();

  /// Cancels the channel with [cause], an `IoException` saying it was
  /// cancelled by default: the reader fails with it.
  void cancel([Object? cause]);
}
