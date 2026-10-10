/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

/// The answer of a Unicode normalization quick check, UAX #15's
/// `Quick_Check` property and algorithm.
@internal
enum QuickCheckResult {
  /// The text is in the normalization form.
  yes,

  /// The text may be in the normalization form; only normalizing it tells.
  maybe,

  /// The text is not in the normalization form.
  no,
}
