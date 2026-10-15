/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// Thrown when a charset is asked for by a name no supported charset has,
/// Java's `UnsupportedCharsetException`.
///
/// The name usually comes from outside, such as the `charset` parameter of
/// a content type, so it is an [Exception], not an error.
final class UnsupportedCharsetException implements Exception {
  /// Creates the exception for [charsetName].
  const UnsupportedCharsetException(this.charsetName);

  /// The name asked for.
  final String charsetName;

  /// Describes the exception.
  ///
  /// Returns a message that names the charset.
  @override
  String toString() =>
      'UnsupportedCharsetException: the charset "$charsetName" is not '
      'supported';
}
