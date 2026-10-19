/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:essentia_io/src/exception/closed_byte_channel_exception.dart';
import 'package:meta/meta.dart';

/// How a byte channel was closed: normally, without an [origin], or
/// cancelled with one.
@internal
final class CloseToken {
  /// Creates the token of a channel closed with [origin], thrown at
  /// [stackTrace].
  const CloseToken(this.origin, [this.stackTrace]);

  /// The token of a channel closed normally.
  static const closed = CloseToken(null);

  /// What the channel was cancelled with, `null` when it was closed
  /// normally.
  final Object? origin;

  /// Where [origin] was thrown, where it is known.
  final StackTrace? stackTrace;

  /// The failure a user of the channel sees: a new cancellation for a
  /// cancellation, so that it is not mistaken for that of the user's own
  /// job, and [origin] wrapped by [wrap] for anything else.
  ///
  /// Returns it, or `null` for a channel closed normally.
  Exception? wrapCause([
    ClosedByteChannelException Function(Object cause, StackTrace? stackTrace)
        wrap =
        ClosedByteChannelException.new,
  ]) {
    final Object? cause = origin;
    if (cause == null) {
      return null;
    }
    if (cause is CancellationException) {
      return CancellationException(cause.message, cause);
    }
    return wrap(cause, stackTrace);
  }

  /// Throws what [wrapCause] makes of [origin], if anything.
  void throwCause([
    ClosedByteChannelException Function(Object cause, StackTrace? stackTrace)
        wrap =
        ClosedByteChannelException.new,
  ]) {
    final Exception? cause = wrapCause(wrap);
    if (cause != null) {
      throw cause;
    }
  }
}
