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

/// A declared program parameter whose resolved value is of type [V].
///
/// What `Parameters.parameter` and `Parameters.flag` hand back, once the
/// declaration is finished, is one of these. It is read through [value]
/// after the schema was loaded:
///
/// ```dart
/// final Parameter<int> port =
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
