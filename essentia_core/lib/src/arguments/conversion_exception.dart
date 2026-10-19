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

import 'package:essentia_core/src/lang/causal.dart';

/// Thrown by a converter for a value it cannot convert.
///
/// The parameter loader catches this and turns it into one entry of the
/// report it assembles, so [message] should describe the expectation rather
/// than repeat the offending value: the report already prints the value and
/// the parameter it belongs to. `"is not a valid integer"` reads correctly
/// in that context; `"could not parse 'x'"` duplicates what the report
/// shows.
final class ConversionException implements Exception, Causal {
  /// Creates the exception describing what the converter expected, with the
  /// [cause] that made the value unusable when there was one.
  const ConversionException(this.message, [this.cause]);

  /// The description of what the converter expected.
  final String message;

  /// The failure that made the value unusable, or `null`.
  @override
  final Object? cause;

  /// Where [cause] was thrown, which is not recorded: `null`.
  @override
  StackTrace? get causeStackTrace => null;

  /// The [message].
  @override
  String toString() => message;
}
