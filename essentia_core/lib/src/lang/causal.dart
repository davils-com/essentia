/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// Something that happened because of an earlier failure, which it keeps.
///
/// Dart's errors and exceptions carry no cause of their own. The ones of
/// Essentia that wrap another failure implement this interface, so code
/// that reports a failure can walk the chain of causes without knowing
/// every type that has one:
///
/// ```dart
/// Object? failure = error;
/// while (failure is Causal) {
///   failure = failure.cause;
/// }
/// ```
abstract interface class Causal {
  /// The failure behind this one, or `null` when there was none.
  Object? get cause;

  /// Where [cause] was thrown, or `null` when that is not known.
  StackTrace? get causeStackTrace;
}
