/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// The part an attendee plays, the `ROLE` of RFC 5545.
///
/// It is open: a value RFC 5545 does not name is kept as it is.
extension type const IcsRole(String value) implements Object {
  /// Chairs the meeting.
  static const chair = IcsRole('CHAIR');

  /// Must take part.
  static const required = IcsRole('REQ-PARTICIPANT');

  /// May take part.
  static const optional = IcsRole('OPT-PARTICIPANT');

  /// Is informed only.
  static const nonParticipant = IcsRole('NON-PARTICIPANT');
}
