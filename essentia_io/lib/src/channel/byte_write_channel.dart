/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
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
