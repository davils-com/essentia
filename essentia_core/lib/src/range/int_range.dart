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

part of 'int_progression.dart';

/// The largest number of elements [Random.nextInt] can choose from.
const _largestRandomBound = 0x100000000;

/// The integers from [start] up to and including [endInclusive].
///
/// An [IntProgression] with a step of one that is also a [ClosedRange] of
/// integers, so it can be iterated, indexed and searched without iterating.
final class IntRange extends IntProgression implements ClosedRange<int> {
  /// Creates the range from [start] up to and including [endInclusive];
  /// it is empty when [start] lies beyond [endInclusive].
  const IntRange(int start, int endInclusive) : super._(start, endInclusive, 1);

  /// Picks an element of the range at random from [source], or from a new
  /// [Random] when none is given.
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

  /// Picks an element of the range at random like [random].
  ///
  /// Returns the element, or `null` when the range is empty.
  ///
  /// Throws a [RangeError] if the range holds more elements than
  /// [Random.nextInt] can choose from.
  @useResult
  int? randomOrNull([Random? source]) => isEmpty ? null : random(source);

  /// Describes the range as `start..endInclusive`.
  ///
  /// Returns the description.
  @override
  String toString() => '$start..$endInclusive';
}
