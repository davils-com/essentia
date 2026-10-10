/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/channels/channel_result.dart';
import 'package:essentia/src/lang/causal.dart';

/// A channel operation that failed because the channel is closed, with the
/// [cause] it was closed with.
final class ChannelClosed<T> extends ChannelFailure<T> implements Causal {
  /// Creates the result of a channel closed for [cause], `null` for a
  /// normal close.
  const ChannelClosed(this.cause);

  /// Why the channel was closed, `null` for a normal close.
  @override
  final Object? cause;

  /// Where [cause] was thrown, which is not recorded: `null`.
  @override
  StackTrace? get causeStackTrace => null;

  /// See [ChannelFailure.isClosed].
  @override
  bool get isClosed => true;

  /// See [ChannelFailure.getOrThrow].
  @override
  T getOrThrow() {
    final Object? failure = cause;
    if (failure != null) {
      Error.throwWithStackTrace(failure, StackTrace.current);
    }
    return super.getOrThrow();
  }

  /// See [ChannelFailure.exceptionOrNull].
  @override
  Object? exceptionOrNull() => cause;

  /// Whether [other] is a closed result with the same cause.
  @override
  bool operator ==(Object other) =>
      other is ChannelClosed<Object?> && other.cause == cause;

  /// The hash of the cause.
  @override
  int get hashCode => Object.hash(ChannelClosed, cause);

  /// Renders the cause, like Kotlin's `Closed(...)`.
  @override
  String toString() => 'ChannelClosed($cause)';
}
