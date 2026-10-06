/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/stream/switch_map.dart';

/// Kotlin's terminal `Flow` operators for streams.
extension StreamCollection<T> on Stream<T> {
  /// Runs [action] for every element and abandons the action of an element
  /// as soon as the next one arrives, the counterpart of Kotlin's
  /// `collectLatest`.
  ///
  /// Dart cannot cancel a running future, so an abandoned action keeps
  /// running; only its completion is no longer waited for.
  ///
  /// Returns a future that completes once this stream ended and the action
  /// of its last element completed, or with the first error of this stream
  /// or of an action that was still awaited.
  Future<void> collectLatest(Future<void> Function(T element) action) =>
      switchMap<T, void>(
        this,
        (element) => Stream<void>.fromFuture(action(element)),
      ).drain<void>();

  /// Finds the first element that satisfies [test], the counterpart of
  /// Kotlin's `firstOrNull` with a predicate.
  ///
  /// Stops listening to this stream as soon as an element matches.
  ///
  /// Returns the element, or `null` when this stream ends without one; the
  /// future fails with the first error of this stream or of [test].
  Future<T?> firstWhereOrNull(bool Function(T element) test) async {
    await for (final T element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }

  /// Counts the elements that satisfy [test], the counterpart of Kotlin's
  /// `count` with a predicate.
  ///
  /// Returns the count once this stream ended; the future fails with the
  /// first error of this stream or of [test].
  Future<int> countWhere(bool Function(T element) test) => where(test).length;
}
