/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:math';

import 'package:meta/meta.dart';

/// Kotlin's slices from the end of a list, which copy by index instead of
/// reading every element.
extension ListSlicing<T> on List<T> {
  /// Takes the last [count] elements, or all of them if there are fewer.
  ///
  /// Kotlin's `takeLast`.
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
  /// Kotlin's `dropLast`.
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
  /// Kotlin's `takeLastWhile`.
  ///
  /// Returns them as an unmodifiable list.
  @useResult
  List<T> takeLastWhile(bool Function(T element) predicate) =>
      List<T>.unmodifiable(sublist(_trailingStart(predicate)));

  /// Leaves out the trailing elements that [predicate] accepts.
  ///
  /// Kotlin's `dropLastWhile`.
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
