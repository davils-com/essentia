/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:collection';

import 'package:essentia/src/collection/window_remainder.dart';
import 'package:essentia/src/collection/windows.dart';
import 'package:meta/meta.dart';

/// Kotlin's windowing functions: sliding windows, neighbouring pairs, and
/// taking or dropping elements from the end.
extension IterableWindowing<T> on Iterable<T> {
  /// Slides a window of [size] elements over the elements, moving it on by
  /// [step] elements each time; [remainder] decides whether the partial
  /// windows at the end are kept.
  ///
  /// Kotlin's `windowed` of a sequence: the source is read once, and only
  /// as the windows are requested.
  ///
  /// Returns the windows as unmodifiable lists, lazily.
  ///
  /// Throws a [RangeError] if [size] or [step] is smaller than one.
  @useResult
  Iterable<List<T>> windowed(
    int size, {
    int step = 1,
    WindowRemainder remainder = WindowRemainder.drop,
  }) => windowsOf(
    this,
    checkedWindowShape((size: size, step: step, remainder: remainder)),
  );

  /// Pairs every element with the one after it.
  ///
  /// Kotlin's `zipWithNext`.
  ///
  /// Returns the pairs, lazily; none for fewer than two elements.
  @useResult
  Iterable<(T, T)> zipWithNext() sync* {
    final Iterator<T> elements = iterator;
    if (!elements.moveNext()) {
      return;
    }
    T previous = elements.current;
    while (elements.moveNext()) {
      final T current = elements.current;
      yield (previous, current);
      previous = current;
    }
  }

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
    final tail = ListQueue<T>(count + 1);
    for (final element in this) {
      tail.add(element);
      if (tail.length > count) {
        tail.removeFirst();
      }
    }
    return List<T>.unmodifiable(tail);
  }

  /// Leaves out the last [count] elements, or all of them if there are
  /// fewer.
  ///
  /// Kotlin's `dropLast`; an endless source is passed on lazily.
  ///
  /// Returns the remaining elements, lazily.
  ///
  /// Throws a [RangeError] if [count] is negative.
  @useResult
  Iterable<T> dropLast(int count) {
    RangeError.checkNotNegative(count, 'count');
    return _dropLast(count);
  }

  /// Passes on every element once [count] more have been read after it.
  ///
  /// Returns the elements but the last [count], lazily.
  Iterable<T> _dropLast(int count) sync* {
    final pending = ListQueue<T>(count + 1);
    for (final element in this) {
      pending.add(element);
      if (pending.length > count) {
        yield pending.removeFirst();
      }
    }
  }

  /// Takes the trailing elements that [predicate] accepts.
  ///
  /// Kotlin's `takeLastWhile`.
  ///
  /// Returns them as an unmodifiable list, empty if the last element is
  /// not accepted.
  @useResult
  List<T> takeLastWhile(bool Function(T element) predicate) {
    final tail = <T>[];
    for (final element in this) {
      if (!predicate(element)) {
        tail.clear();
        continue;
      }
      tail.add(element);
    }
    return List<T>.unmodifiable(tail);
  }

  /// Leaves out the trailing elements that [predicate] accepts.
  ///
  /// Kotlin's `dropLastWhile`; elements are passed on as soon as one after
  /// them is rejected, so an endless source is read lazily.
  ///
  /// Returns the remaining elements, lazily.
  @useResult
  Iterable<T> dropLastWhile(bool Function(T element) predicate) sync* {
    final pending = <T>[];
    for (final element in this) {
      pending.add(element);
      if (!predicate(element)) {
        yield* pending;
        pending.clear();
      }
    }
  }
}
