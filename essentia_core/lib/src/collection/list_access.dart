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

import 'package:essentia_core/src/range/int_progression.dart';
import 'package:meta/meta.dart';

/// Reads the elements of a list by index.
extension ListAccess<T> on List<T> {
  /// The index of the last element; minus one for an empty list.
  int get lastIndex => length - 1;

  /// Every valid index of the list.
  IntRange get indices => IntRange(0, lastIndex);

  /// The element at [index], or a fallback when it lies outside.
  ///
  /// Returns the element, or what [fallback] returns for [index] when it
  /// lies outside the list.
  @useResult
  T getOrElse(int index, T Function(int index) fallback) =>
      0 <= index && index < length ? this[index] : fallback(index);

  /// The elements at [indices], in their order.
  ///
  /// Returns an unmodifiable list of the elements.
  ///
  /// Throws a [RangeError] if one of [indices] lies outside the list.
  @useResult
  List<T> elementsAt(Iterable<int> indices) =>
      List<T>.unmodifiable(indices.map((index) => this[index]));
}
