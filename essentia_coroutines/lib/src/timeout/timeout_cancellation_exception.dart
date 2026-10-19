/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/src/exception/cancellation_exception.dart';
import 'package:meta/meta.dart';

/// Reports that `withTimeout` ran out of time.
///
/// Inside the timed out block it is the cancellation of its job; thrown out
/// of `withTimeout` it tells the caller that the limit passed.
final class TimeoutCancellationException extends CancellationException {
  /// Creates the exception with [message], raised by [coroutine].
  const TimeoutCancellationException(String super.message, {this.coroutine});

  /// The coroutine whose time ran out, which tells `withTimeoutOrNull` its
  /// own timeout apart from an inner one.
  @internal
  final Object? coroutine;

  /// Renders the exception with its message.
  @override
  String toString() => 'TimeoutCancellationException: $message';
}
