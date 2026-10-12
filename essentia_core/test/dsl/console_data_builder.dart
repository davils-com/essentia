/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';

import 'destination_data.dart';

/// Assembles a [ConsoleData].
final class ConsoleDataBuilder extends ValidatingBuilder<ConsoleData> {
  /// The name of the destination.
  var name = 'console';

  /// Whether records are written in colour.
  var colour = true;

  /// Assembles the destination.
  @override
  ConsoleData assemble() => ConsoleData(name, colour: colour);
}
