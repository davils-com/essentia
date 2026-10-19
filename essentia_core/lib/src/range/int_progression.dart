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

import 'package:essentia_core/src/range/closed_range.dart';
import 'package:meta/meta.dart';

part 'int_range.dart';

/// An arithmetic progression of integers from [start] to [endInclusive] in
/// steps of [step].
///
/// A positive step counts upwards, a negative one downwards. The progression
/// ends at the last element the step reaches, so [endInclusive] is always an
/// element of a progression that is not empty. It computes its [length], its
/// elements and [contains] without iterating.
@immutable
final class IntProgression with Iterable<int> {
  /// Creates the progression from [start] towards [endInclusive] in steps
  /// of [step].
  ///
  /// The end is moved to the last element the step reaches.
  ///
  /// Throws an [ArgumentError] if [step] is zero.
  IntProgression(int start, int endInclusive, {int step = 1})
    : this._(start, _lastElement(start, endInclusive, _nonZero(step)), step);

  /// Creates the progression from its exact [start], [endInclusive] and
  /// [step], without moving the end.
  const IntProgression._(this.start, this.endInclusive, this.step);

  /// The first element of the progression.
  final int start;

  /// The last element of the progression, unless it is empty.
  final int endInclusive;

  /// The distance between two neighbouring elements; never zero.
  final int step;

  /// Whether the progression holds no element, because [start] lies beyond
  /// [endInclusive] in the direction of [step].
  @override
  bool get isEmpty => step > 0 ? start > endInclusive : start < endInclusive;

  /// The number of elements, computed without iterating.
  @override
  int get length => isEmpty ? 0 : (endInclusive - start) ~/ step + 1;

  /// Iterates the elements from [start] to [endInclusive].
  @override
  Iterator<int> get iterator =>
      Iterable<int>.generate(length, _elementAtUnchecked).iterator;

  /// The first element.
  ///
  /// Throws a [StateError] if the progression is empty.
  @override
  int get first => isEmpty ? throw StateError('No element') : start;

  /// The last element.
  ///
  /// Throws a [StateError] if the progression is empty.
  @override
  int get last => isEmpty ? throw StateError('No element') : endInclusive;

  /// Whether [element] is an integer the progression reaches, computed
  /// without iterating.
  ///
  /// Returns `true` for an element of the progression.
  @override
  bool contains(Object? element) =>
      element is int &&
      !isEmpty &&
      min(start, endInclusive) <= element &&
      element <= max(start, endInclusive) &&
      (element - start) % step == 0;

  /// The element at [index], computed without iterating.
  ///
  /// Returns the element.
  ///
  /// Throws a [RangeError] if [index] lies outside the progression.
  @override
  int elementAt(int index) =>
      _elementAtUnchecked(RangeError.checkValidIndex(index, this));

  /// The same elements in the opposite order.
  ///
  /// Returns the progression from [endInclusive] back to [start].
  @useResult
  IntProgression reversed() => IntProgression._(endInclusive, start, -step);

  /// The progression with the same start and direction but a step of
  /// [step].
  ///
  /// Returns the new progression, whose end is the last element the new
  /// step reaches.
  ///
  /// Throws an [ArgumentError] if [step] is not positive.
  @useResult
  IntProgression stepBy(int step) {
    if (step <= 0) {
      throw ArgumentError.value(step, 'step', 'must be positive');
    }
    return IntProgression(
      start,
      endInclusive,
      step: this.step > 0 ? step : -step,
    );
  }

  /// The element at [index], without checking that it exists.
  ///
  /// Returns `start + index * step`.
  int _elementAtUnchecked(int index) => start + index * step;

  /// Whether [other] is a progression with the same elements and step;
  /// every empty progression equals every other.
  ///
  /// Returns `true` for an equal progression.
  @override
  bool operator ==(Object other) =>
      other is IntProgression &&
      (isEmpty && other.isEmpty ||
          start == other.start &&
              endInclusive == other.endInclusive &&
              step == other.step);

  /// The hash code of the ends and the step, and zero when empty.
  @override
  int get hashCode => isEmpty ? 0 : Object.hash(start, endInclusive, step);

  /// Describes the progression as `start..end step n` or
  /// `start downTo end step n`.
  ///
  /// Returns the description.
  @override
  String toString() => step > 0
      ? '$start..$endInclusive step $step'
      : '$start downTo $endInclusive step ${-step}';
}

/// Checks that [step] is not zero.
///
/// Returns [step].
///
/// Throws an [ArgumentError] if it is zero.
int _nonZero(int step) {
  if (step == 0) {
    throw ArgumentError.value(step, 'step', 'must not be zero');
  }
  return step;
}

/// The last element a progression from [start] in steps of [step] reaches
/// before passing [end].
///
/// Returns [end] itself when the progression is empty.
int _lastElement(int start, int end, int step) {
  if (step > 0) {
    return start >= end ? end : end - _differenceModulo(end, start, step);
  }
  return start <= end ? end : end + _differenceModulo(start, end, -step);
}

/// The difference of [left] and [right] modulo the positive [modulus],
/// without overflowing.
///
/// Returns a value between zero and [modulus], excluded.
int _differenceModulo(int left, int right, int modulus) =>
    (left % modulus - right % modulus) % modulus;
