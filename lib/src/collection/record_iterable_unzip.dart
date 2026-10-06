/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

/// Kotlin's `unzip` for an iterable of pairs.
extension RecordIterableUnzip<A, B> on Iterable<(A, B)> {
  /// Splits the pairs into their first and their second parts.
  ///
  /// Kotlin's `unzip`.
  ///
  /// Returns both parts as unmodifiable lists in the order of the pairs.
  @useResult
  (List<A>, List<B>) unzip() {
    final firsts = <A>[];
    final seconds = <B>[];
    for (final (first, second) in this) {
      firsts.add(first);
      seconds.add(second);
    }
    return (List<A>.unmodifiable(firsts), List<B>.unmodifiable(seconds));
  }
}
