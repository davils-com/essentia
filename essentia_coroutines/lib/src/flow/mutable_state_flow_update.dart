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

import 'package:essentia_coroutines/src/flow/mutable_state_flow.dart';

/// The updating extensions on `MutableStateFlow`.
extension MutableStateFlowUpdate<T> on MutableStateFlow<T> {
  /// Sets the value to what [function] makes of the current one.
  ///
  /// [function] runs again whenever the value changed while it ran, in a
  /// compare-and-set loop; on one isolate it runs once.
  void update(T Function(T value) function) {
    updateAndGet(function);
  }

  /// Sets the value to what [function] makes of the current one.
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

  /// Sets the value to what [function] makes of the current one.
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
