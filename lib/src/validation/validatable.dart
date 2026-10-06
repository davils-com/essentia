/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/validation/validation_scope.dart';

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
