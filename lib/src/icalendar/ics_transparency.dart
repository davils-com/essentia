/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// Whether an event blocks time, the `TRANSP` of RFC 5545.
///
/// It is open: a value RFC 5545 does not name is kept as it is.
extension type const IcsTransparency(String value) implements Object {
  /// Blocks the time: busy.
  static const opaque = IcsTransparency('OPAQUE');

  /// Leaves the time free.
  static const transparent = IcsTransparency('TRANSPARENT');
}
