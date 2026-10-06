/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/collection/iterable_ordering.dart';
import 'package:meta/meta.dart';

/// Kotlin's `sortedDescending` for an iterable of comparable elements.
extension ComparableIterableOrdering<T extends Comparable<Object>>
    on Iterable<T> {
  /// Sorts the elements by their natural order, largest first; the sort is
  /// stable, so equal elements keep their order.
  ///
  /// Kotlin's `sortedDescending`.
  ///
  /// Returns the sorted elements as an unmodifiable list.
  @useResult
  List<T> sortedDescending() => sortedByDescending((element) => element);
}
