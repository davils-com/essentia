/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// A calculation on dates and times whose result does not exist: a moment
/// beyond the range of an `Instant`, or a local time a shift of the clocks
/// skips when `ZoneResolution.strict` was asked for.
final class DateTimeArithmeticException implements Exception {
  /// Creates the exception that tells what went wrong in [message].
  const DateTimeArithmeticException(this.message);

  /// What went wrong.
  final String message;

  /// Describes the exception.
  @override
  String toString() => 'DateTimeArithmeticException: $message';
}
