/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// A declared program parameter whose resolved value is of type [V].
///
/// What `Parameters.parameter` and `Parameters.flag` hand back, once the
/// declaration is finished, is one of these. It is read through [value]
/// after the schema was loaded:
///
/// ```dart
/// late final Parameter<int> port =
///     parameter(['--port']).integer().required();
///
/// startServer(parameters.port.value);
/// ```
abstract interface class Parameter<V> {
  /// The resolved value.
  ///
  /// Reading it costs a list access: loading built an immutable snapshot,
  /// and nothing here converts, validates or waits.
  ///
  /// Throws a `ParametersNotLoadedError` if the schema was not loaded yet,
  /// and a [StateError] if the parameter is not listed in the schema's
  /// declared parameters.
  V get value;
}
