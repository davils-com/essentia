/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// Something whose release has to wait for work in flight.
///
/// This is `Disposable` for the case where letting go is not instantaneous:
/// a queue that should be drained, a connection that should be told it is
/// going away, a worker that should finish the item it is holding. A type
/// that can do both offers `Disposable.dispose` for the abrupt path and
/// this one for the orderly path, and says which is which.
///
/// [dispose] is idempotent. A second call completes once the first has
/// settled rather than starting the teardown again.
abstract interface class DisposableAsync {
  /// Releases what this object holds, completing when that is done.
  ///
  /// The object is unusable afterwards. How long this takes is the
  /// implementation's to document, and where it waits on somebody else's
  /// code it says so.
  Future<void> dispose();
}
