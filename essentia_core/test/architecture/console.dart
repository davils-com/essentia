/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'destination.dart';

/// A destination writing to the console.
final class Console extends Destination {
  /// Creates the console [name], in colour when [colour] is set.
  const Console(super.name, {required this.colour});

  /// Whether records are written in colour.
  final bool colour;
}
