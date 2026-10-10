/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// The state of an event, the `STATUS` of a `VEVENT` in RFC 5545.
///
/// It is open: a value RFC 5545 does not name is kept as it is.
extension type const IcsEventStatus(String value) implements Object {
  /// Not settled yet.
  static const tentative = IcsEventStatus('TENTATIVE');

  /// Settled.
  static const confirmed = IcsEventStatus('CONFIRMED');

  /// Called off.
  static const cancelled = IcsEventStatus('CANCELLED');
}
