/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/flow/mutable_shared_flow.dart';
import 'package:essentia/src/flow/state_flow.dart';
import 'package:essentia/src/flow/state_flow_impl.dart';

/// A state flow whose value is set, Kotlin's `MutableStateFlow`.
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
  /// Creates a state flow holding [value], Kotlin's `MutableStateFlow()`.
  factory MutableStateFlow(T value) = StateFlowImpl<T>;

  /// The current value, Kotlin's `value`.
  @override
  T get value;

  /// Sets the current value, Kotlin's `value`; listeners are told unless
  /// it equals the current one.
  set value(T value);

  /// Sets the value to [update] if the current one equals [expect],
  /// Kotlin's `compareAndSet`.
  ///
  /// Returns `true` when the current value equals [expect], also when
  /// [update] equals it as well and nothing changes.
  bool compareAndSet(T expect, T update);

  /// Sets the value like the [value] setter, Kotlin's `emit` of a state
  /// flow.
  ///
  /// Returns a completed future; it never waits.
  @override
  Future<void> emit(T value);

  /// Sets the value like the [value] setter, Kotlin's `tryEmit` of a state
  /// flow.
  ///
  /// Returns `true`.
  @override
  bool tryEmit(T value);

  /// Not supported by a state flow, which always has a value, Kotlin's
  /// `resetReplayCache` of a state flow.
  ///
  /// Throws an [UnsupportedError].
  @override
  void resetReplayCache();

  /// A read-only view of this flow, Kotlin's `asStateFlow`.
  ///
  /// Returns the view, which cannot be cast back to set the value.
  StateFlow<T> asStateFlow();
}
