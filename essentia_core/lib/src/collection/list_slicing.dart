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

import 'dart:math';

import 'package:meta/meta.dart';

/// Slices from the end of a list, which copy by index instead of reading
/// every element.
extension ListSlicing<T> on List<T> {
  /// Takes the last [count] elements, or all of them if there are fewer.
  ///
  /// Returns them as an unmodifiable list.
  ///
  /// Throws a [RangeError] if [count] is negative.
  @useResult
  List<T> takeLast(int count) {
    RangeError.checkNotNegative(count, 'count');
    return List<T>.unmodifiable(sublist(max(0, length - count)));
  }

  /// Leaves out the last [count] elements, or all of them if there are
  /// fewer.
  ///
  /// Returns the remaining elements as an unmodifiable list.
  ///
  /// Throws a [RangeError] if [count] is negative.
  @useResult
  List<T> dropLast(int count) {
    RangeError.checkNotNegative(count, 'count');
    return List<T>.unmodifiable(sublist(0, max(0, length - count)));
  }

  /// Takes the trailing elements that [predicate] accepts.
  ///
  /// Returns them as an unmodifiable list.
  @useResult
  List<T> takeLastWhile(bool Function(T element) predicate) =>
      List<T>.unmodifiable(sublist(_trailingStart(predicate)));

  /// Leaves out the trailing elements that [predicate] accepts.
  ///
  /// Returns the remaining elements as an unmodifiable list.
  @useResult
  List<T> dropLastWhile(bool Function(T element) predicate) =>
      List<T>.unmodifiable(sublist(0, _trailingStart(predicate)));

  /// Finds where the trailing run of elements [predicate] accepts begins.
  ///
  /// Returns the index of its first element, [length] for no such run.
  int _trailingStart(bool Function(T element) predicate) =>
      lastIndexWhere((element) => !predicate(element)) + 1;
}
