/*
 * Copyright 2026 Davils
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:essentia_core/src/result/result.dart';

/// Splits and combines a collection of results.
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

  /// Splits the results into their values and their errors.
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
