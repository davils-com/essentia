/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_io/src/exception/io_exception.dart';

/// Thrown when the peer of a connection closed it, Ktor's
/// `ConnectionClosedException`.
final class ConnectionClosedException extends IoException {
  /// Creates the exception with [message].
  const ConnectionClosedException([super.message = 'Connection was closed']);

  /// The name of the exception in its description.
  @override
  String get kind => 'ConnectionClosedException';
}
