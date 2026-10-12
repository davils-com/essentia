/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// A hot stream whose values are shared between all of its listeners,
/// Kotlin's `SharedFlow`.
///
/// A shared flow never ends: a listener stays subscribed until it cancels
/// or the job it listened in is cancelled. A new listener gets the
/// [replayCache] first and then every value emitted after it subscribed.
///
/// A listener that listens inside a coroutine is ended when the job of
/// that coroutine is cancelled: it gets the `CancellationException` of
/// the job as an error event, and then the stream is done for it. So
/// `await for` over a shared flow inside a coroutine, and `collect`,
/// end with that exception instead of keeping the cancelled job waiting
/// forever. A plain `listen` without `onError` inside a coroutine sees
/// that exception as an uncaught error; prefer `collect` and `launchIn`.
///
/// A listener that pauses - `await for` does while its body runs - holds
/// its place in the shared buffer, so a slow listener slows the emitters
/// down instead of losing values, as Kotlin's suspending collectors do.
///
/// It is a broadcast stream: [isBroadcast] is `true`.
abstract interface class SharedFlow<T> implements Stream<T> {
  /// The values a new listener gets first, oldest first, Kotlin's
  /// `replayCache`.
  ///
  /// The list is a snapshot and cannot be changed.
  List<T> get replayCache;
}
