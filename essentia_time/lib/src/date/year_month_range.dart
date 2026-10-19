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
import 'package:essentia_time/src/date/year_month.dart';
import 'package:meta/meta.dart';

/// The months from [start] up to and including [endInclusive].
///
/// It is a [ClosedRange] that can also be iterated month by month. It is
/// empty when [start] lies after [endInclusive].
@immutable
final class YearMonthRange extends Iterable<YearMonth>
    implements ClosedRange<YearMonth> {
  /// Creates the range from [start] up to and including [endInclusive].
  const YearMonthRange(this.start, this.endInclusive);

  /// The first month of the range.
  @override
  final YearMonth start;

  /// The last month of the range, which the range contains.
  @override
  final YearMonth endInclusive;

  /// Whether [start] lies after [endInclusive].
  @override
  bool get isEmpty => start.isAfter(endInclusive);

  /// Whether the range holds a month.
  @override
  bool get isNotEmpty => !isEmpty;

  /// How many months the range holds.
  @override
  int get length => isEmpty ? 0 : start.monthsUntil(endInclusive) + 1;

  /// The months of the range, from [start] on.
  @override
  Iterator<YearMonth> get iterator =>
      Iterable<YearMonth>.generate(length, start.plusMonths).iterator;

  /// The month [index] months after [start].
  ///
  /// Throws a [RangeError] outside the range.
  @override
  YearMonth elementAt(int index) {
    RangeError.checkValidIndex(index, this, 'index', length);
    return start.plusMonths(index);
  }

  /// Whether [value] is a month between [start] and [endInclusive], both
  /// included.
  @override
  bool contains(Object? value) =>
      value is YearMonth &&
      !value.isBefore(start) &&
      !value.isAfter(endInclusive);

  /// Whether [other] is a range with the same ends, or both are empty.
  @override
  bool operator ==(Object other) =>
      other is YearMonthRange &&
      ((isEmpty && other.isEmpty) ||
          (other.start == start && other.endInclusive == endInclusive));

  /// A hash of the range.
  @override
  int get hashCode => isEmpty ? 0 : Object.hash(start, endInclusive);

  /// Describes the range as `start..endInclusive`.
  @override
  String toString() => '$start..$endInclusive';
}
