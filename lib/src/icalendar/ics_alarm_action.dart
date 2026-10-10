/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// What an alarm does, the `ACTION` of a `VALARM` in RFC 5545.
///
/// It is open: a value RFC 5545 does not name is kept as it is.
extension type const IcsAlarmAction(String value) implements Object {
  /// Shows a message.
  static const display = IcsAlarmAction('DISPLAY');

  /// Plays a sound.
  static const audio = IcsAlarmAction('AUDIO');

  /// Sends an email.
  static const email = IcsAlarmAction('EMAIL');
}
