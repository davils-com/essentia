/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

/// One slot of the workspace form validated by the standalone validation
/// tests.
@immutable
final class FormSlot {
  /// Creates the slot [name] holding [size] units.
  const FormSlot(this.name, this.size);

  /// The name of the slot.
  final String name;

  /// How many units the slot holds.
  final int size;
}
