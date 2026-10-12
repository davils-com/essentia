/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// Where a bus or one of its topics is in its life.
///
/// One value rather than a pair of booleans, because shutting down and
/// having shut down are different states and code that tracked them
/// separately could be in neither or in both.
///
/// The order is the only order these occur in. Nothing goes back.
enum BusState {
  /// Accepting publications and delivering them.
  running,

  /// No longer accepting publications, still delivering what it already
  /// holds.
  ///
  /// Entered only by an orderly shutdown. An abrupt one goes straight to
  /// [closed].
  draining,

  /// Finished. Every subscription is cancelled and every publication is
  /// refused.
  closed,
}
