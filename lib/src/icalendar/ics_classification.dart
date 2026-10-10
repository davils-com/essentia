/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// Who may see an entry, the `CLASS` of RFC 5545.
///
/// It is open: a value RFC 5545 does not name is kept as it is.
extension type const IcsClassification(String value) implements Object {
  /// Everyone.
  static const public = IcsClassification('PUBLIC');

  /// Only the owner.
  static const private = IcsClassification('PRIVATE');

  /// Only those allowed.
  static const confidential = IcsClassification('CONFIDENTIAL');
}
