/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/range/closed_range.dart';
import 'package:essentia/src/time/local_date.dart';
import 'package:meta/meta.dart';

/// The dates from [start] up to and including [endInclusive], Kotlin's
/// `kotlinx.datetime.LocalDateRange`.
///
/// It is a [ClosedRange] that can also be iterated day by day, indexed and
/// measured without iterating. It is empty when [start] lies after
/// [endInclusive].
@immutable
final class LocalDateRange extends Iterable<LocalDate>
    implements ClosedRange<LocalDate> {
  /// Creates the range from [start] up to and including [endInclusive].
  const LocalDateRange(this.start, this.endInclusive);

  /// The first date of the range.
  @override
  final LocalDate start;

  /// The last date of the range, which the range contains.
  @override
  final LocalDate endInclusive;

  /// The date after the range.
  LocalDate get endExclusive => endInclusive.plusDays(1);

  /// Whether [start] lies after [endInclusive].
  @override
  bool get isEmpty => start.isAfter(endInclusive);

  /// Whether the range holds a date.
  @override
  bool get isNotEmpty => !isEmpty;

  /// How many dates the range holds.
  @override
  int get length => isEmpty ? 0 : start.daysUntil(endInclusive) + 1;

  /// The dates of the range, from [start] on.
  @override
  Iterator<LocalDate> get iterator =>
      Iterable<LocalDate>.generate(length, start.plusDays).iterator;

  /// The date [index] days after [start].
  ///
  /// Throws a [RangeError] outside the range.
  @override
  LocalDate elementAt(int index) {
    RangeError.checkValidIndex(index, this, 'index', length);
    return start.plusDays(index);
  }

  /// Whether [value] is a date between [start] and [endInclusive], both
  /// included.
  @override
  bool contains(Object? value) =>
      value is LocalDate &&
      !value.isBefore(start) &&
      !value.isAfter(endInclusive);

  /// Whether this range and [other] share a date.
  bool overlaps(LocalDateRange other) =>
      isNotEmpty &&
      other.isNotEmpty &&
      !other.start.isAfter(endInclusive) &&
      !start.isAfter(other.endInclusive);

  /// The dates both this range and [other] hold, or `null` when they share
  /// none.
  LocalDateRange? intersect(LocalDateRange other) {
    if (!overlaps(other)) {
      return null;
    }
    return LocalDateRange(
      start.isAfter(other.start) ? start : other.start,
      endInclusive.isBefore(other.endInclusive)
          ? endInclusive
          : other.endInclusive,
    );
  }

  /// Whether [other] is a range with the same ends, or both are empty.
  @override
  bool operator ==(Object other) =>
      other is LocalDateRange &&
      ((isEmpty && other.isEmpty) ||
          (other.start == start && other.endInclusive == endInclusive));

  /// A hash of the range.
  @override
  int get hashCode => isEmpty ? 0 : Object.hash(start, endInclusive);

  /// Describes the range as `start..endInclusive`, like Kotlin.
  @override
  String toString() => '$start..$endInclusive';
}
