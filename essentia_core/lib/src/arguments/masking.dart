/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

/// What a masked value is rendered as.
@internal
const mask = '****';

/// Renders [value] with its contents masked, keeping only its shape.
///
/// Returns one mask per element of a list, `null` for nothing, and a single
/// mask otherwise.
@internal
String maskValue(Object? value) {
  if (value is List<Object?>) {
    return '[${value.map((_) => mask).join(', ')}]';
  }
  if (value == null) {
    return 'null';
  }
  return mask;
}
