/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
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
