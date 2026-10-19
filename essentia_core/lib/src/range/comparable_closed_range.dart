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

part of 'closed_range.dart';

/// The [ClosedRange] of any comparable values, compared with their own
/// `compareTo`.
@immutable
final class _ComparableClosedRange<T extends Comparable<Object>>
    implements ClosedRange<T> {
  /// Creates the range from [start] up to and including [endInclusive].
  const _ComparableClosedRange(this.start, this.endInclusive);

  /// The smallest value of the range.
  @override
  final T start;

  /// The largest value of the range, which the range contains.
  @override
  final T endInclusive;

  /// Whether [start] lies beyond [endInclusive].
  @override
  bool get isEmpty => start.compareTo(endInclusive) > 0;

  /// Whether [value] lies between [start] and [endInclusive], both
  /// included.
  ///
  /// Returns `true` for a value of the range.
  @override
  bool contains(T value) =>
      start.compareTo(value) <= 0 && value.compareTo(endInclusive) <= 0;

  /// Whether [other] is a range of the same kind with equal ends.
  ///
  /// Returns `true` for an equal range.
  @override
  bool operator ==(Object other) =>
      other is _ComparableClosedRange<T> &&
      other.start == start &&
      other.endInclusive == endInclusive;

  /// The hash code of both ends.
  @override
  int get hashCode => Object.hash(start, endInclusive);

  /// Describes the range as `start..endInclusive`.
  ///
  /// Returns the description.
  @override
  String toString() => '$start..$endInclusive';
}
