/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

/// What became of an element offered to a mailbox without waiting.
@internal
enum MailboxOffer {
  /// The mailbox took the element.
  accepted,

  /// The mailbox had no room and nobody was waiting for the element.
  full,

  /// The mailbox no longer takes anything.
  closed,
}
