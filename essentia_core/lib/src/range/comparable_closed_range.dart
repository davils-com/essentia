/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
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
