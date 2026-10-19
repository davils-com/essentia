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

import 'package:essentia_core/essentia_core.dart';
import 'package:essentia_time/src/date/local_date.dart';
import 'package:meta/meta.dart';

/// The dates from [start] up to and including [endInclusive].
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

  /// Describes the range as `start..endInclusive`.
  @override
  String toString() => '$start..$endInclusive';
}
