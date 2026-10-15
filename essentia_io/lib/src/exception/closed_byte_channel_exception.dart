/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_io/src/exception/io_exception.dart';

/// Thrown when a byte channel is used after it was cancelled, Ktor's
/// `ClosedByteChannelException`; [cause] is what it was cancelled with.
base class ClosedByteChannelException extends IoException {
  /// Creates the exception for a channel cancelled with [cause].
  ClosedByteChannelException([Object? cause, StackTrace? causeStackTrace])
    : super(_messageOf(cause), cause: cause, causeStackTrace: causeStackTrace);

  /// The message that tells what the channel was cancelled with.
  ///
  /// Returns it.
  static String _messageOf(Object? cause) {
    if (cause == null) {
      return 'The channel was closed';
    }
    if (cause is IoException) {
      return cause.message;
    }
    return 'The channel was cancelled';
  }

  /// The name of the exception in its description.
  @override
  String get kind => 'ClosedByteChannelException';
}
