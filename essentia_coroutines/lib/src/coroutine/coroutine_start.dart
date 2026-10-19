/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// How a coroutine builder starts its coroutine.
enum CoroutineStart {
  /// Dispatches the body right away; a coroutine cancelled before its body ran
  /// never runs it. The name avoids `default`, a reserved word in Dart.
  defaultStart,

  /// Starts the coroutine only when it is started, joined or awaited.
  lazy,

  /// Dispatches the body right away, and runs it even if the coroutine is
  /// cancelled before it ran.
  atomic,

  /// Runs the body at once, in the caller's frame, up to its first
  /// suspension.
  undispatched,
}
