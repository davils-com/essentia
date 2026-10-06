/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

/// Thrown by `requirePrincipal()` when the current zone holds no principal.
///
/// Nothing about permission: code that requires a caller and finds none was
/// reached without the edge that establishes one having run. That is a
/// defect in how the call was set up, and treating it as "access denied"
/// would hide it.
final class PrincipalMissingException implements Exception {
  /// Creates the exception.
  @internal
  const PrincipalMissingException();

  /// What went wrong and how to fix it.
  String get message =>
      'No principal in the current zone. Establish one at the edge that '
      'verified the caller, with runAsPrincipal(principal(...), body), '
      'before calling code that requires it.';

  /// The [message].
  @override
  String toString() => 'PrincipalMissingException: $message';
}
