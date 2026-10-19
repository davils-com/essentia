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

import 'package:essentia_core/src/validation/validation_scope.dart';

/// Something that can say what is wrong with itself.
///
/// An immutable data class implements this to state its own invariants,
/// once, next to the fields they constrain. Its builder is then unable to
/// produce an instance that breaks them.
///
/// ```dart
/// final class LoggingData implements Validatable {
///   const LoggingData(this.rootLevel, this.sinks);
///
///   final LogLevel rootLevel;
///   final List<SinkData> sinks;
///
///   @override
///   void validate(ValidationScope scope) {
///     if (sinks.isEmpty) {
///       scope.fail('at least one sink must be configured', property: 'sinks');
///     }
///   }
/// }
/// ```
///
/// Report problems through [ValidationScope.fail] and return normally.
/// Never throw here: a throw abandons every remaining rule and reduces the
/// report to whatever happened to be checked first.
abstract interface class Validatable {
  /// States what is wrong with this instance, reporting through [scope].
  void validate(ValidationScope scope);
}
