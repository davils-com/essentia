/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/src/channels/channel_closed.dart';
import 'package:meta/meta.dart';

/// The outcome of a channel operation that does not wait.
///
/// It is a [ChannelSuccess] carrying the value, a [ChannelFailure] when the
/// channel was full or empty, or a [ChannelClosed] - a failure as well -
/// when the channel is closed. Match it with an exhaustive `switch`, the
/// [ChannelClosed] case before the [ChannelFailure] case:
///
/// ```dart
/// switch (channel.tryReceive()) {
///   case ChannelSuccess(:final value):
///     handle(value);
///   case ChannelClosed(:final cause):
///     finish(cause);
///   case ChannelFailure():
///     waitForMore();
/// }
/// ```
@immutable
sealed class ChannelResult<T> {
  /// Creates a result.
  const ChannelResult();

  /// Whether the operation succeeded.
  bool get isSuccess;

  /// Whether the operation failed, because the channel was full, empty or
  /// closed.
  bool get isFailure => !isSuccess;

  /// Whether the operation failed because the channel is closed.
  bool get isClosed;

  /// The value of a successful operation, or `null` for a failure.
  ///
  /// Returns the value, or `null` for a failure.
  T? getOrNull();

  /// The value of a successful operation, throwing for a failure.
  ///
  /// Returns the value.
  ///
  /// Throws the cause of a [ChannelClosed] that has one, and a [StateError]
  /// for any other failure.
  T getOrThrow();

  /// Why the channel is closed.
  ///
  /// Returns the cause of a [ChannelClosed], or `null` for a success, a
  /// plain failure and a channel closed without a cause.
  Object? exceptionOrNull();
}

/// A channel operation that succeeded with [value].
final class ChannelSuccess<T> extends ChannelResult<T> {
  /// Creates the result carrying [value].
  const ChannelSuccess(this.value);

  /// The element received, or `null` for a send.
  final T value;

  /// See [ChannelResult.isSuccess].
  @override
  bool get isSuccess => true;

  /// See [ChannelResult.isClosed].
  @override
  bool get isClosed => false;

  /// See [ChannelResult.getOrNull].
  @override
  T? getOrNull() => value;

  /// See [ChannelResult.getOrThrow].
  @override
  T getOrThrow() => value;

  /// See [ChannelResult.exceptionOrNull].
  @override
  Object? exceptionOrNull() => null;

  /// Whether [other] is a success with an equal value.
  @override
  bool operator ==(Object other) =>
      other is ChannelSuccess<Object?> && other.value == value;

  /// The hash of the value.
  @override
  int get hashCode => Object.hash(ChannelSuccess, value);

  /// Renders the value.
  @override
  String toString() => 'ChannelSuccess($value)';
}

/// A channel operation that failed: the channel was full for a send, or
/// empty for a receive. A [ChannelClosed] is a failure as well.
base class ChannelFailure<T> extends ChannelResult<T> {
  /// Creates the failure.
  const ChannelFailure();

  /// See [ChannelResult.isSuccess].
  @override
  bool get isSuccess => false;

  /// See [ChannelResult.isClosed].
  @override
  bool get isClosed => false;

  /// See [ChannelResult.getOrNull].
  @override
  T? getOrNull() => null;

  /// See [ChannelResult.getOrThrow].
  @override
  T getOrThrow() => throw StateError(
    "Trying to call 'getOrThrow' on a failed channel result: $this",
  );

  /// See [ChannelResult.exceptionOrNull].
  @override
  Object? exceptionOrNull() => null;

  /// Whether [other] is a failure too, but not a [ChannelClosed].
  @override
  bool operator ==(Object other) =>
      other is ChannelFailure<Object?> && other is! ChannelClosed<Object?>;

  /// The hash of the kind of result.
  @override
  int get hashCode => (ChannelFailure).hashCode;

  /// Renders the failure.
  @override
  String toString() => 'ChannelFailure';
}
