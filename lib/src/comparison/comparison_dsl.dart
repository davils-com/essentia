/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// A comparator ordering elements by the key [keyOf] selects, ascending,
/// Kotlin's `compareBy`.
///
/// Returns the comparator.
Comparator<T> compareBy<T, K extends Comparable<Object>>(
  K Function(T element) keyOf,
) =>
    (left, right) => keyOf(left).compareTo(keyOf(right));

/// A comparator ordering elements by the key [keyOf] selects, descending,
/// Kotlin's `compareByDescending`.
///
/// Returns the comparator.
Comparator<T> compareByDescending<T, K extends Comparable<Object>>(
  K Function(T element) keyOf,
) =>
    (left, right) => keyOf(right).compareTo(keyOf(left));

/// A comparator ordering comparable values by their natural order,
/// Kotlin's `naturalOrder`.
///
/// Returns the comparator.
Comparator<T> naturalOrder<T extends Comparable<Object>>() =>
    (left, right) => left.compareTo(right);

/// A comparator ordering comparable values by the reverse of their natural
/// order, Kotlin's `reverseOrder`.
///
/// Returns the comparator.
Comparator<T> reverseOrder<T extends Comparable<Object>>() =>
    (left, right) => right.compareTo(left);

/// A comparator that orders `null` before every value and compares two
/// values with [comparator], Kotlin's `nullsFirst`.
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
/// values with [comparator], Kotlin's `nullsLast`.
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
/// every value, Kotlin's `compareValues`.
///
/// Returns a negative number when [left] comes first, zero when both are
/// equal and a positive number when [right] comes first.
int compareValues<T extends Comparable<Object>>(T? left, T? right) =>
    nullsFirst<T>(naturalOrder<T>())(left, right);
