/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/src/flow/mutable_state_flow.dart';

/// Kotlin's updating extensions on `MutableStateFlow`.
extension MutableStateFlowUpdate<T> on MutableStateFlow<T> {
  /// Sets the value to what [function] makes of the current one, Kotlin's
  /// `update`.
  ///
  /// [function] runs again whenever the value changed while it ran, as
  /// Kotlin's compare-and-set loop does; on one isolate it runs once.
  void update(T Function(T value) function) {
    updateAndGet(function);
  }

  /// Sets the value to what [function] makes of the current one, Kotlin's
  /// `updateAndGet`.
  ///
  /// Returns the new value.
  T updateAndGet(T Function(T value) function) {
    while (true) {
      final T previous = value;
      final T next = function(previous);
      if (compareAndSet(previous, next)) {
        return next;
      }
    }
  }

  /// Sets the value to what [function] makes of the current one, Kotlin's
  /// `getAndUpdate`.
  ///
  /// Returns the previous value.
  T getAndUpdate(T Function(T value) function) {
    while (true) {
      final T previous = value;
      final T next = function(previous);
      if (compareAndSet(previous, next)) {
        return previous;
      }
    }
  }
}
