/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/result/result.dart';

/// The operations of [Result] on a future of a result, so a chain of
/// asynchronous steps reads like the synchronous one.
///
/// Every member awaits the result and calls the member of [Result] with the
/// same name, which mirrors the Kotlin function of that name.
extension ResultAsync<T> on Future<Result<T>> {
  /// Awaits the result and transforms its value, [Result.map].
  ///
  /// Returns a success carrying the transformed value, or the failure.
  ///
  /// Throws whatever this future or [transform] throws.
  Future<Result<R>> map<R>(R Function(T value) transform) async =>
      (await this).map(transform);

  /// Awaits the result and transforms its value with the awaited
  /// [transform], [Result.mapAsync].
  ///
  /// Returns a success carrying the transformed value, or the failure.
  ///
  /// Throws whatever this future or [transform] throws.
  Future<Result<R>> mapAsync<R>(Future<R> Function(T value) transform) async =>
      (await this).mapAsync(transform);

  /// Awaits the result and chains it into the result [transform] returns,
  /// [Result.flatMap].
  ///
  /// Returns what [transform] returns, or the failure.
  ///
  /// Throws whatever this future or [transform] throws.
  Future<Result<R>> flatMap<R>(Result<R> Function(T value) transform) async =>
      (await this).flatMap(transform);

  /// Awaits the result and chains it into the result the awaited
  /// [transform] returns, [Result.flatMapAsync].
  ///
  /// Returns what [transform] completes with, or the failure.
  ///
  /// Throws whatever this future or [transform] throws.
  Future<Result<R>> flatMapAsync<R>(
    Future<Result<R>> Function(T value) transform,
  ) async => (await this).flatMapAsync(transform);

  /// Awaits the result and replaces the error of a failure,
  /// [Result.mapError].
  ///
  /// Returns the success, or a failure carrying the new error.
  ///
  /// Throws whatever this future or [transform] throws.
  Future<Result<T>> mapError(
    Object Function(Object error, StackTrace stackTrace) transform,
  ) async => (await this).mapError(transform);

  /// Awaits the result and turns a failure into a success, Kotlin's
  /// `recover`.
  ///
  /// Returns the success, or a success carrying what [transform] returns.
  ///
  /// Throws whatever this future or [transform] throws.
  Future<Result<T>> recover(
    T Function(Object error, StackTrace stackTrace) transform,
  ) async => (await this).recover(transform);

  /// Awaits the result and runs [action] on the value of a success,
  /// Kotlin's `onSuccess`.
  ///
  /// Returns the awaited result.
  ///
  /// Throws whatever this future or [action] throws.
  Future<Result<T>> onSuccess(void Function(T value) action) async =>
      (await this).onSuccess(action);

  /// Awaits the result and runs [action] on the error of a failure,
  /// Kotlin's `onFailure`.
  ///
  /// Returns the awaited result.
  ///
  /// Throws whatever this future or [action] throws.
  Future<Result<T>> onFailure(
    void Function(Object error, StackTrace stackTrace) action,
  ) async => (await this).onFailure(action);

  /// Awaits the result and turns it into one value, Kotlin's `fold`.
  ///
  /// Returns what the matching branch returns.
  ///
  /// Throws whatever this future or the called branch throws.
  Future<R> fold<R>({
    required R Function(T value) onSuccess,
    required R Function(Object error, StackTrace stackTrace) onFailure,
  }) async => (await this).fold(onSuccess: onSuccess, onFailure: onFailure);

  /// Awaits the result and unwraps its value or builds a fallback, Kotlin's
  /// `getOrElse`.
  ///
  /// Returns the value of a success, or what [onFailure] returns.
  ///
  /// Throws whatever this future or [onFailure] throws.
  Future<T> getOrElse(
    T Function(Object error, StackTrace stackTrace) onFailure,
  ) async => (await this).getOrElse(onFailure);

  /// Awaits the result and unwraps its value, Kotlin's `getOrThrow`.
  ///
  /// Returns the value of a success.
  ///
  /// Throws the error of a failure with its original stack trace, or
  /// whatever this future throws.
  Future<T> getOrThrow() async => (await this).getOrThrow();
}
