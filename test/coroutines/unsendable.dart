/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:isolate';

/// An error that cannot cross to another isolate, because it holds a port.
final class Unsendable implements Exception {
  /// Creates the error holding [port].
  Unsendable(this.port);

  /// What makes the error unsendable.
  final ReceivePort port;

  /// Renders the error.
  @override
  String toString() => 'unsendable';
}
