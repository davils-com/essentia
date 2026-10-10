/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// A time zone that does not exist or cannot be read, Kotlin's
/// `kotlinx.datetime.IllegalTimeZoneException`.
final class IllegalTimeZoneException implements Exception {
  /// Creates the exception that tells what went wrong in [message].
  const IllegalTimeZoneException(this.message);

  /// What went wrong.
  final String message;

  /// Describes the exception.
  @override
  String toString() => 'IllegalTimeZoneException: $message';
}
