/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

/// Pads [label] to [width], the first column of an aligned listing.
///
/// A label that is already at least as wide as the column is followed by a
/// single space instead, so that it never runs into the column next to it.
///
/// Returns the padded label.
@internal
String column(String label, int width) {
  if (label.length >= width) {
    return '$label ';
  }
  return label.padRight(width);
}
