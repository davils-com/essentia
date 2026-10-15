/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_io/src/exception/closed_byte_channel_exception.dart';

/// Thrown when a byte channel is written after it was closed or cancelled,
/// Ktor's `ClosedWriteChannelException`.
final class ClosedWriteChannelException extends ClosedByteChannelException {
  /// Creates the exception for a channel closed, or cancelled with
  /// [cause].
  ClosedWriteChannelException([super.cause, super.causeStackTrace]);

  /// The name of the exception in its description.
  @override
  String get kind => 'ClosedWriteChannelException';
}
