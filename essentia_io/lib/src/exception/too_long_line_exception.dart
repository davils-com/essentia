/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_io/src/exception/io_exception.dart';

/// Thrown when a line is longer than a reader allows, Ktor's
/// `TooLongLineException`.
final class TooLongLineException extends IoException {
  /// Creates the exception with [message].
  const TooLongLineException(super.message);

  /// The name of the exception in its description.
  @override
  String get kind => 'TooLongLineException';
}
