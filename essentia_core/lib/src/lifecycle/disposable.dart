/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// Something that holds resources until it is told to let go of them.
///
/// A disposed object is finished for good rather than merely closed for
/// this block.
///
/// [dispose] is idempotent. Calling it a second time does nothing and does
/// not fail, so a shutdown path that cannot know whether it already ran
/// does not have to guess.
abstract interface class Disposable {
  /// Releases what this object holds.
  ///
  /// The object is unusable afterwards. Implementations decide what an
  /// operation on a disposed object does, but they say so, and they never
  /// make a second [dispose] an error.
  void dispose();
}
