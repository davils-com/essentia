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

/// A comparator ordering elements by the key [keyOf] selects, ascending.
///
/// Returns the comparator.
Comparator<T> compareBy<T, K extends Comparable<Object>>(
  K Function(T element) keyOf,
) =>
    (left, right) => keyOf(left).compareTo(keyOf(right));

/// A comparator ordering elements by the key [keyOf] selects, descending.
///
/// Returns the comparator.
Comparator<T> compareByDescending<T, K extends Comparable<Object>>(
  K Function(T element) keyOf,
) =>
    (left, right) => keyOf(right).compareTo(keyOf(left));

/// A comparator ordering comparable values by their natural order.
///
/// Returns the comparator.
Comparator<T> naturalOrder<T extends Comparable<Object>>() =>
    (left, right) => left.compareTo(right);

/// A comparator ordering comparable values by the reverse of their natural
/// order.
///
/// Returns the comparator.
Comparator<T> reverseOrder<T extends Comparable<Object>>() =>
    (left, right) => right.compareTo(left);

/// A comparator that orders `null` before every value and compares two
/// values with [comparator].
///
/// Returns the comparator, which considers two `null`s equal.
Comparator<T?> nullsFirst<T extends Object>(Comparator<T> comparator) =>
    (left, right) => switch ((left, right)) {
      (null, null) => 0,
      (null, _) => -1,
      (_, null) => 1,
      (final T present, final T other) => comparator(present, other),
    };

/// A comparator that orders `null` after every value and compares two
/// values with [comparator].
///
/// Returns the comparator, which considers two `null`s equal.
Comparator<T?> nullsLast<T extends Object>(Comparator<T> comparator) =>
    (left, right) => switch ((left, right)) {
      (null, null) => 0,
      (null, _) => 1,
      (_, null) => -1,
      (final T present, final T other) => comparator(present, other),
    };

/// Compares [left] with [right] by their natural order, with `null` below
/// every value.
///
/// Returns a negative number when [left] comes first, zero when both are
/// equal and a positive number when [right] comes first.
int compareValues<T extends Comparable<Object>>(T? left, T? right) =>
    nullsFirst<T>(naturalOrder<T>())(left, right);
