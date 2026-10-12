/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';

/// The failure of a library with a validation pass of its own, which
/// extends [ValidationException] from outside Essentia.
final class DecodingFailure extends ValidationException {
  /// Creates the failure for [report].
  const DecodingFailure(super.report);
}
