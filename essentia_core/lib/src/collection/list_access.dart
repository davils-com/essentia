/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/range/int_progression.dart';
import 'package:meta/meta.dart';

/// Reads the elements of a list by index, Kotlin's `lastIndex`,
/// `indices`, `getOrElse` and `slice`.
extension ListAccess<T> on List<T> {
  /// The index of the last element, Kotlin's `lastIndex`; minus one for
  /// an empty list.
  int get lastIndex => length - 1;

  /// Every valid index of the list, Kotlin's `indices`.
  IntRange get indices => IntRange(0, lastIndex);

  /// The element at [index], Kotlin's `getOrElse`.
  ///
  /// Returns the element, or what [fallback] returns for [index] when it
  /// lies outside the list.
  @useResult
  T getOrElse(int index, T Function(int index) fallback) =>
      0 <= index && index < length ? this[index] : fallback(index);

  /// The elements at [indices], in their order, Kotlin's `slice`.
  ///
  /// Returns an unmodifiable list of the elements.
  ///
  /// Throws a [RangeError] if one of [indices] lies outside the list.
  @useResult
  List<T> elementsAt(Iterable<int> indices) =>
      List<T>.unmodifiable(indices.map((index) => this[index]));
}
