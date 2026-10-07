/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// The ball of the ping-pong example of the Kotlin channels guide.
final class Ball {
  /// Creates a ball hit [hits] times.
  Ball(this.hits);

  /// How often the ball was hit.
  int hits;

  /// Renders the ball like the Kotlin data class.
  @override
  String toString() => 'Ball(hits=$hits)';
}
