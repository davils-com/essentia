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

part of 'open_end_range.dart';

/// The [OpenEndRange] of any comparable values, compared with their own
/// `compareTo`.
@immutable
final class _ComparableOpenEndRange<T extends Comparable<Object>>
    implements OpenEndRange<T> {
  /// Creates the range from [start] up to but excluding [endExclusive].
  const _ComparableOpenEndRange(this.start, this.endExclusive);

  /// The smallest value of the range.
  @override
  final T start;

  /// The first value beyond the range, which the range does not contain.
  @override
  final T endExclusive;

  /// Whether [start] reaches [endExclusive].
  @override
  bool get isEmpty => start.compareTo(endExclusive) >= 0;

  /// Whether [value] lies between [start], included, and [endExclusive],
  /// excluded.
  ///
  /// Returns `true` for a value of the range.
  @override
  bool contains(T value) =>
      start.compareTo(value) <= 0 && value.compareTo(endExclusive) < 0;

  /// Whether [other] is a range of the same kind with equal ends.
  ///
  /// Returns `true` for an equal range.
  @override
  bool operator ==(Object other) =>
      other is _ComparableOpenEndRange<T> &&
      other.start == start &&
      other.endExclusive == endExclusive;

  /// The hash code of both ends.
  @override
  int get hashCode => Object.hash(start, endExclusive);

  /// Describes the range as `start..<endExclusive`.
  ///
  /// Returns the description.
  @override
  String toString() => '$start..<$endExclusive';
}
