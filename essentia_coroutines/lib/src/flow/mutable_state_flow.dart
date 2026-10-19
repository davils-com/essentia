/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/src/flow/mutable_shared_flow.dart';
import 'package:essentia_coroutines/src/flow/state_flow.dart';
import 'package:essentia_coroutines/src/flow/state_flow_impl.dart';

/// A state flow whose value is set.
///
/// Setting [value] never waits: listeners that are busy skip to the latest
/// value. Setting a value equal (`==`) to the current one changes nothing.
///
/// ```dart
/// final class CounterModel {
///   final _counter = MutableStateFlow(0);
///
///   StateFlow<int> get counter => _counter.asStateFlow();
///
///   void inc() => _counter.update((count) => count + 1);
/// }
/// ```
abstract interface class MutableStateFlow<T>
    implements StateFlow<T>, MutableSharedFlow<T> {
  /// Creates a state flow holding [value].
  factory MutableStateFlow(T value) = StateFlowImpl<T>;

  /// The current value.
  @override
  T get value;

  /// Sets the current value; listeners are told unless it equals the
  /// current one.
  set value(T value);

  /// Sets the value to [update] if the current one equals [expect].
  ///
  /// Returns `true` when the current value equals [expect], also when
  /// [update] equals it as well and nothing changes.
  bool compareAndSet(T expect, T update);

  /// Sets the value like the [value] setter.
  ///
  /// Returns a completed future; it never waits.
  @override
  Future<void> emit(T value);

  /// Sets the value like the [value] setter.
  ///
  /// Returns `true`.
  @override
  bool tryEmit(T value);

  /// Not supported by a state flow, which always has a value.
  ///
  /// Throws an [UnsupportedError].
  @override
  void resetReplayCache();

  /// A read-only view of this flow.
  ///
  /// Returns the view, which cannot be cast back to set the value.
  StateFlow<T> asStateFlow();
}
