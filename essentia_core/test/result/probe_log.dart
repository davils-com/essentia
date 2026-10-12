/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// A log the result tests record into, to see which callbacks ran and in
/// which order.
final class ProbeLog {
  /// Everything recorded so far, in order.
  final entries = <String>[];

  /// Appends [entry] to [entries].
  void record(String entry) => entries.add(entry);
}
