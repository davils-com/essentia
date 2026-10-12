/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/result/result.dart';

/// Splits and combines a collection of results.
///
/// Kotlin's standard library has no counterpart; the members follow
/// `partition` on collections and the `values`, `errors` and `combine` of
/// the common Kotlin result libraries.
extension ResultIterable<T> on Iterable<Result<T>> {
  /// The values of every success, in order.
  ///
  /// Returns an unmodifiable list.
  List<T> get values =>
      List.unmodifiable(whereType<Success<T>>().map((result) => result.value));

  /// The errors of every failure, in order.
  ///
  /// Returns an unmodifiable list.
  List<Object> get errors =>
      List.unmodifiable(whereType<Failure<T>>().map((result) => result.error));

  /// Splits the results into their values and their errors, like Kotlin's
  /// `partition`.
  ///
  /// Returns both unmodifiable lists, each in order.
  ({List<T> values, List<Object> errors}) partition() =>
      (values: values, errors: errors);

  /// Turns the results into one result of all values.
  ///
  /// Returns a success carrying the values of every success when nothing
  /// failed, or the first failure with its stack trace.
  Result<List<T>> sequence() {
    final Iterable<Failure<T>> failed = whereType<Failure<T>>();
    if (failed.isEmpty) {
      return Success<List<T>>(values);
    }
    final Failure<T> first = failed.first;
    return Failure<List<T>>(first.error, first.stackTrace);
  }
}
