/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

/// How many values a parameter resolves to, and what happens without one.
@internal
enum Cardinality {
  /// At most one value; absent is `null`.
  optional,

  /// Exactly one value; absent is a violation.
  required,

  /// At most one value; absent is the declared default.
  defaulted,

  /// Any number of values, collected into a list.
  multiple,
}
