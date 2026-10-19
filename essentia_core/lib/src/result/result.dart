/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/result/result_dsl.dart';
import 'package:meta/meta.dart';

/// The outcome of an operation that either produced a value or failed.
///
/// A result is a [Success] carrying the value or a [Failure] carrying the
/// error and the stack trace it was thrown with. The family is sealed, so a
/// `switch` over a result is exhaustive:
///
/// ```dart
/// final String text = switch (runCatching(() => int.parse(input))) {
///   Success<int>(:final int value) => 'parsed $value',
///   Failure<int>(:final Object error) => 'failed with $error',
/// };
/// ```
///
/// A failure keeps its stack trace next to the error, because a Dart error
/// does not carry one by itself.
@immutable
sealed class Result<T> {
  /// Creates a result; only [Success] and [Failure] extend it.
  const Result();

  /// Creates a successful result carrying [value].
  const factory Result.success(T value) = Success<T>;

  /// Creates a failed result carrying [error] and [stackTrace].
  ///
  /// The stack trace defaults to [StackTrace.empty].
  const factory Result.failure(Object error, [StackTrace stackTrace]) =
      Failure<T>;

  /// Whether this result is a [Success].
  bool get isSuccess => switch (this) {
    Success<T>() => true,
    Failure<T>() => false,
  };

  /// Whether this result is a [Failure].
  bool get isFailure => switch (this) {
    Success<T>() => false,
    Failure<T>() => true,
  };

  /// The value of a success.
  ///
  /// Returns the value, or `null` for a failure.
  T? get valueOrNull => switch (this) {
    Success<T>(:final T value) => value,
    Failure<T>() => null,
  };

  /// The error of a failure.
  ///
  /// Returns the error, or `null` for a success.
  Object? get errorOrNull => switch (this) {
    Success<T>() => null,
    Failure<T>(:final Object error) => error,
  };

  /// The stack trace of a failure.
  ///
  /// Returns the stack trace, or `null` for a success.
  StackTrace? get stackTraceOrNull => switch (this) {
    Success<T>() => null,
    Failure<T>(:final StackTrace stackTrace) => stackTrace,
  };

  /// Unwraps the value.
  ///
  /// Returns the value of a success.
  ///
  /// Throws the error of a failure with its original stack trace.
  T getOrThrow() => switch (this) {
    Success<T>(:final T value) => value,
    Failure<T>(:final Object error, :final StackTrace stackTrace) =>
      Error.throwWithStackTrace(error, stackTrace),
  };

  /// Unwraps the value or falls back to [fallback].
  ///
  /// Returns the value of a success, or [fallback] for a failure.
  T getOrDefault(T fallback) => switch (this) {
    Success<T>(:final T value) => value,
    Failure<T>() => fallback,
  };

  /// Unwraps the value or builds a fallback with [onFailure].
  ///
  /// [onFailure] runs only for a failure and receives its error and stack
  /// trace.
  ///
  /// Returns the value of a success, or what [onFailure] returns.
  ///
  /// Throws whatever [onFailure] throws.
  T getOrElse(T Function(Object error, StackTrace stackTrace) onFailure) =>
      switch (this) {
        Success<T>(:final T value) => value,
        Failure<T>(:final Object error, :final StackTrace stackTrace) =>
          onFailure(error, stackTrace),
      };

  /// Turns this result into one value.
  ///
  /// Returns what [onSuccess] returns for a success, or what [onFailure]
  /// returns for a failure.
  ///
  /// Throws whatever the called branch throws.
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(Object error, StackTrace stackTrace) onFailure,
  }) => switch (this) {
    Success<T>(:final T value) => onSuccess(value),
    Failure<T>(:final Object error, :final StackTrace stackTrace) => onFailure(
      error,
      stackTrace,
    ),
  };

  /// Transforms the value of a success with [transform].
  ///
  /// A failure passes through with its error and stack trace, and
  /// [transform] is not called.
  ///
  /// Returns a success carrying the transformed value, or the failure.
  ///
  /// Throws whatever [transform] throws; see [mapCatching] to catch it.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
    Success<T>(:final T value) => Success<R>(transform(value)),
    Failure<T>(:final Object error, :final StackTrace stackTrace) => Failure<R>(
      error,
      stackTrace,
    ),
  };

  /// Transforms the value of a success with [transform] and catches what it
  /// throws.
  ///
  /// Returns a success carrying the transformed value, a failure carrying
  /// what [transform] threw, or the original failure.
  Result<R> mapCatching<R>(R Function(T value) transform) => switch (this) {
    Success<T>(:final T value) => runCatching<R>(() => transform(value)),
    Failure<T>(:final Object error, :final StackTrace stackTrace) => Failure<R>(
      error,
      stackTrace,
    ),
  };

  /// Turns a failure into a success with [transform].
  ///
  /// Returns this result for a success, or a success carrying what
  /// [transform] returns.
  ///
  /// Throws whatever [transform] throws; see [recoverCatching] to catch it.
  Result<T> recover(
    T Function(Object error, StackTrace stackTrace) transform,
  ) => switch (this) {
    Success<T>() => this,
    Failure<T>(:final Object error, :final StackTrace stackTrace) => Success<T>(
      transform(error, stackTrace),
    ),
  };

  /// Turns a failure into a success with [transform] and catches what it
  /// throws.
  ///
  /// Returns this result for a success, a success carrying what [transform]
  /// returns, or a failure carrying what [transform] threw.
  Result<T> recoverCatching(
    T Function(Object error, StackTrace stackTrace) transform,
  ) => switch (this) {
    Success<T>() => this,
    Failure<T>(:final Object error, :final StackTrace stackTrace) =>
      runCatching<T>(() => transform(error, stackTrace)),
  };

  /// Chains a success into the result [transform] returns.
  ///
  /// Returns what [transform] returns, or the failure with its error and
  /// stack trace.
  ///
  /// Throws whatever [transform] throws.
  Result<R> flatMap<R>(Result<R> Function(T value) transform) => switch (this) {
    Success<T>(:final T value) => transform(value),
    Failure<T>(:final Object error, :final StackTrace stackTrace) => Failure<R>(
      error,
      stackTrace,
    ),
  };

  /// Replaces the error of a failure with what [transform] returns and keeps
  /// its stack trace.
  ///
  /// Returns this result for a success, or a failure carrying the new error.
  ///
  /// Throws whatever [transform] throws.
  Result<T> mapError(
    Object Function(Object error, StackTrace stackTrace) transform,
  ) => switch (this) {
    Success<T>() => this,
    Failure<T>(:final Object error, :final StackTrace stackTrace) => Failure<T>(
      transform(error, stackTrace),
      stackTrace,
    ),
  };

  /// Pairs the value of this result with the value of [other].
  ///
  /// Returns a success carrying both values, or the first failure, this
  /// result first.
  Result<(T, R)> zip<R>(Result<R> other) => switch (this) {
    Success<T>(:final T value) => other.map((second) => (value, second)),
    Failure<T>(:final Object error, :final StackTrace stackTrace) =>
      Failure<(T, R)>(error, stackTrace),
  };

  /// Transforms the value of a success with the awaited [transform], the
  /// [map] of an asynchronous block.
  ///
  /// Returns a success carrying the transformed value, or the failure.
  ///
  /// Throws whatever [transform] throws.
  Future<Result<R>> mapAsync<R>(Future<R> Function(T value) transform) async =>
      switch (this) {
        Success<T>(:final T value) => Success<R>(await transform(value)),
        Failure<T>(:final Object error, :final StackTrace stackTrace) =>
          Failure<R>(error, stackTrace),
      };

  /// Chains a success into the result the awaited [transform] returns, the
  /// [flatMap] of an asynchronous block.
  ///
  /// Returns what [transform] completes with, or the failure.
  ///
  /// Throws whatever [transform] throws.
  Future<Result<R>> flatMapAsync<R>(
    Future<Result<R>> Function(T value) transform,
  ) async => switch (this) {
    Success<T>(:final T value) => await transform(value),
    Failure<T>(:final Object error, :final StackTrace stackTrace) => Failure<R>(
      error,
      stackTrace,
    ),
  };

  /// Runs [action] on the value of a success.
  ///
  /// Returns this result.
  ///
  /// Throws whatever [action] throws.
  Result<T> onSuccess(void Function(T value) action) => switch (this) {
    Success<T>(:final T value) => _returnedAfter(this, () => action(value)),
    Failure<T>() => this,
  };

  /// Runs [action] on the error and stack trace of a failure.
  ///
  /// Returns this result.
  ///
  /// Throws whatever [action] throws.
  Result<T> onFailure(
    void Function(Object error, StackTrace stackTrace) action,
  ) => switch (this) {
    Success<T>() => this,
    Failure<T>(:final Object error, :final StackTrace stackTrace) =>
      _returnedAfter(this, () => action(error, stackTrace)),
  };
}

/// A result that carries a value.
final class Success<T> extends Result<T> {
  /// Creates a success carrying [value].
  const Success(this.value);

  /// The value the operation produced.
  final T value;

  /// Whether [other] is a success carrying an equal value.
  ///
  /// Returns `true` for an equal success, whatever its type argument.
  @override
  bool operator ==(Object other) =>
      other is Success<Object?> && other.value == value;

  /// The hash code of the value.
  @override
  int get hashCode => Object.hashAll([value]);

  /// Describes the success as `Success(value)`.
  ///
  /// Returns the description.
  @override
  String toString() => 'Success($value)';
}

/// A result that carries an error and its stack trace.
final class Failure<T> extends Result<T> {
  /// Creates a failure carrying [error] and [stackTrace], which defaults to
  /// [StackTrace.empty].
  const Failure(this.error, [this.stackTrace = StackTrace.empty]);

  /// The error the operation failed with.
  final Object error;

  /// The stack trace [error] was thrown with.
  final StackTrace stackTrace;

  /// Whether [other] is a failure carrying an equal error and stack trace.
  ///
  /// Returns `true` for an equal failure, whatever its type argument.
  @override
  bool operator ==(Object other) =>
      other is Failure<Object?> &&
      other.error == error &&
      other.stackTrace == stackTrace;

  /// The hash code of the error and the stack trace.
  @override
  int get hashCode => Object.hash(error, stackTrace);

  /// Describes the failure as `Failure(error)`.
  ///
  /// Returns the description.
  @override
  String toString() => 'Failure($error)';
}

/// Runs [action] and hands back [receiver], which is how [Result.onSuccess]
/// and [Result.onFailure] return the result they observed.
///
/// Returns [receiver].
///
/// Throws whatever [action] throws.
R _returnedAfter<R>(R receiver, void Function() action) {
  action();
  return receiver;
}
