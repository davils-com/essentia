/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_io/src/exception/io_exception.dart';

/// Thrown when data ends before what was asked for is complete.
final class EofException extends IoException {
  /// Creates the exception with [message].
  const EofException(super.message);

  /// The name of the exception in its description.
  @override
  String get kind => 'EofException';
}
