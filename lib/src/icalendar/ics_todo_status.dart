/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// The state of a to-do, the `STATUS` of a `VTODO` in RFC 5545.
///
/// It is open: a value RFC 5545 does not name is kept as it is.
extension type const IcsTodoStatus(String value) implements Object {
  /// Still to do.
  static const needsAction = IcsTodoStatus('NEEDS-ACTION');

  /// Done.
  static const completed = IcsTodoStatus('COMPLETED');

  /// Under way.
  static const inProcess = IcsTodoStatus('IN-PROCESS');

  /// Called off.
  static const cancelled = IcsTodoStatus('CANCELLED');
}
