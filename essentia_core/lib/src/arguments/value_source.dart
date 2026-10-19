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

import 'package:essentia_core/src/arguments/parameter_info.dart';

/// Supplies values for parameters that were not passed on the command line.
///
/// This is the extension point for configuration that lives somewhere
/// Essentia knows nothing about: a secret store, a configuration service, a
/// file format of the application's choosing. [read] is asynchronous because
/// reaching such a place is real work.
///
/// Sources are consulted in the order they are passed, and only for
/// parameters still without a value, so the first source that answers
/// wins. A source is asked once per parameter during loading and never
/// again.
///
/// A source that fails - a timeout, a refused connection, a response it
/// cannot parse - is an operational condition rather than a problem with
/// the arguments, and it is reported as one: an [Exception] it throws is
/// caught, and the parameter gets a violation coded
/// `ParameterViolationCodes.sourceUnavailable`, alongside every other
/// problem the load found. Later sources are still asked.
abstract interface class ValueSource {
  /// The name this source is reported under when a value it supplied turns
  /// out to be unusable.
  String get name;

  /// Reads the value for [parameter].
  ///
  /// The value is returned as text and goes through exactly the same
  /// conversion and validation as one passed on the command line.
  ///
  /// Returns the value, or `null` when this source does not have one.
  ///
  /// Throws any [Exception] when the source cannot answer; it is reported
  /// rather than propagated.
  Future<String?> read(ParameterInfo parameter);
}
