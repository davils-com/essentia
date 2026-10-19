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

import 'package:essentia_core/src/lazy/initialized_lazy.dart';
import 'package:essentia_core/src/lazy/initializer_lazy.dart';
import 'package:essentia_core/src/lazy/lazy.dart';

/// Creates a [Lazy] whose value [initializer] computes on the first read.
///
/// The contract is the only one an isolate needs:
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

/// Creates a [Lazy] that holds the already known [value].
///
/// Returns a [Lazy] that is initialised from the start.
Lazy<T> lazyOf<T>(T value) => InitializedLazy<T>(value);
