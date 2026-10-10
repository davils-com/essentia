/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// How an attendee answered an invitation, the `PARTSTAT` of RFC 5545.
///
/// It is open: a value RFC 5545 does not name, such as an `X-` one, is
/// kept as it is.
extension type const IcsParticipation(String value) implements Object {
  /// Not answered yet.
  static const needsAction = IcsParticipation('NEEDS-ACTION');

  /// Accepted.
  static const accepted = IcsParticipation('ACCEPTED');

  /// Declined.
  static const declined = IcsParticipation('DECLINED');

  /// Accepted with reservation.
  static const tentative = IcsParticipation('TENTATIVE');

  /// Handed on to someone else.
  static const delegated = IcsParticipation('DELEGATED');

  /// Done, for a to-do.
  static const completed = IcsParticipation('COMPLETED');

  /// Under way, for a to-do.
  static const inProcess = IcsParticipation('IN-PROCESS');
}
