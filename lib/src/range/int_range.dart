/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

part of 'int_progression.dart';

/// The largest number of elements [Random.nextInt] can choose from.
const _largestRandomBound = 0x100000000;

/// The integers from [start] up to and including [endInclusive], Kotlin's
/// `IntRange`.
///
/// An [IntProgression] with a step of one that is also a [ClosedRange] of
/// integers, so it can be iterated, indexed and searched without iterating.
final class IntRange extends IntProgression implements ClosedRange<int> {
  /// Creates the range from [start] up to and including [endInclusive];
  /// it is empty when [start] lies beyond [endInclusive].
  const IntRange(int start, int endInclusive) : super._(start, endInclusive, 1);

  /// Picks an element of the range at random from [source], or from a new
  /// [Random] when none is given, Kotlin's `random`.
  ///
  /// Returns the element.
  ///
  /// Throws a [StateError] if the range is empty, and a [RangeError] if it
  /// holds more elements than [Random.nextInt] can choose from.
  @useResult
  int random([Random? source]) {
    if (isEmpty) {
      throw StateError('Cannot pick a random element of the empty range $this');
    }
    RangeError.checkValueInInterval(length, 1, _largestRandomBound, 'length');
    return start + (source ?? Random()).nextInt(length);
  }

  /// Picks an element of the range at random like [random], Kotlin's
  /// `randomOrNull`.
  ///
  /// Returns the element, or `null` when the range is empty.
  ///
  /// Throws a [RangeError] if the range holds more elements than
  /// [Random.nextInt] can choose from.
  @useResult
  int? randomOrNull([Random? source]) => isEmpty ? null : random(source);

  /// Describes the range as `start..endInclusive`, like Kotlin.
  ///
  /// Returns the description.
  @override
  String toString() => '$start..$endInclusive';
}
