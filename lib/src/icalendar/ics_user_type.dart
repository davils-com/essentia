/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// What kind of calendar user an attendee is, the `CUTYPE` of RFC 5545.
///
/// It is open: a value RFC 5545 does not name is kept as it is.
extension type const IcsUserType(String value) implements Object {
  /// A person.
  static const individual = IcsUserType('INDIVIDUAL');

  /// A group of people.
  static const group = IcsUserType('GROUP');

  /// A physical resource, such as a projector.
  static const resource = IcsUserType('RESOURCE');

  /// A room.
  static const room = IcsUserType('ROOM');

  /// Not known.
  static const unknown = IcsUserType('UNKNOWN');
}
