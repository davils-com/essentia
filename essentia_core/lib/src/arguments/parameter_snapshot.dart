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

import 'package:essentia_core/src/arguments/value_origin.dart';
import 'package:essentia_core/src/validation/violation.dart';
import 'package:meta/meta.dart';

/// Everything a load resolved, immutable from then on.
@internal
@immutable
final class ParameterSnapshot {
  /// Creates the snapshot of [values] that came from [origins].
  ParameterSnapshot(
    List<Object?> values,
    List<ValueOrigin?> origins,
    List<String> rest,
    List<String> unknown,
    List<Violation> warnings,
  ) : _values = List<Object?>.unmodifiable(values),
      _origins = List<ValueOrigin?>.unmodifiable(origins),
      rest = List<String>.unmodifiable(rest),
      unknown = List<String>.unmodifiable(unknown),
      warnings = List<Violation>.unmodifiable(warnings);

  /// The values by ordinal.
  final List<Object?> _values;

  /// Where each value came from, by ordinal.
  final List<ValueOrigin?> _origins;

  /// The arguments after the `--` terminator.
  final List<String> rest;

  /// The arguments that matched no parameter.
  final List<String> unknown;

  /// Everything reported that did not stop the load.
  final List<Violation> warnings;

  /// The value of the parameter at [ordinal].
  ///
  /// Returns the value.
  Object? valueAt(int ordinal) => _values[ordinal];

  /// Where the value of the parameter at [ordinal] came from.
  ///
  /// Returns the origin, or `null` when the parameter has no value.
  ValueOrigin? originAt(int ordinal) => _origins[ordinal];
}
