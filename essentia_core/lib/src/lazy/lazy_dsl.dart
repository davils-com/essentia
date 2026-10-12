/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/lazy/initialized_lazy.dart';
import 'package:essentia_core/src/lazy/initializer_lazy.dart';
import 'package:essentia_core/src/lazy/lazy.dart';

/// Creates a [Lazy] whose value [initializer] computes on the first read,
/// Kotlin's `lazy { }`.
///
/// The contract is Kotlin's `LazyThreadSafetyMode.SYNCHRONIZED`, the only
/// one an isolate needs:
///
/// - [initializer] runs at most once when it returns, and is released
///   afterwards so that what it captured can be collected.
/// - When [initializer] throws, the value stays uncomputed and the next read
///   runs [initializer] again.
/// - A read of the value from inside [initializer] is a programming mistake
///   and throws a [StateError] instead of recursing.
///
/// ```dart
/// final Lazy<Config> config = lazy(() => Config.load(environment));
/// ```
///
/// Returns the uncomputed [Lazy].
Lazy<T> lazy<T>(T Function() initializer) => InitializerLazy<T>(initializer);

/// Creates a [Lazy] that holds the already known [value], Kotlin's
/// `lazyOf`.
///
/// Returns a [Lazy] that is initialised from the start.
Lazy<T> lazyOf<T>(T value) => InitializedLazy<T>(value);
