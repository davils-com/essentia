/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/coroutines/coroutine_dispatcher.dart';
import 'package:essentia/src/coroutines/event_loop_dispatcher.dart';
import 'package:essentia/src/coroutines/isolate_dispatcher.dart';
import 'package:essentia/src/coroutines/unconfined_dispatcher.dart';

/// The dispatchers every program has, Kotlin's `Dispatchers`.
abstract final class Dispatchers {
  /// The event loop of the isolate, the default of every coroutine:
  /// Kotlin's `Main`, `Default` and `IO` in one, because an isolate runs
  /// one thing at a time.
  static const CoroutineDispatcher main = EventLoopDispatcher();

  /// Starts a body at once, in the caller's frame, Kotlin's `Unconfined`.
  static const CoroutineDispatcher unconfined = UnconfinedDispatcher();

  /// Runs every body on a worker isolate of a pool with one isolate per
  /// processor, Kotlin's `Default` for work that keeps a processor busy.
  ///
  /// The body, everything it captures and its result must be sendable
  /// through a `SendPort`; otherwise it fails with an
  /// `IsolateBodyNotSendableError`. Of its context only the
  /// `CoroutineName` and the `PrincipalElement` cross to the isolate; the
  /// body runs there in a coroutine of its own, whose children are not
  /// children of the caller. Cancelling the caller cancels the body on the
  /// isolate, and kills the isolate if the body ignores it for a second.
  /// Idle workers are kept and do not keep the program alive.
  ///
  /// On the web there are no isolates to run on: bodies run on the event
  /// loop, without any parallelism.
  ///
  /// ```dart
  /// final Digest digest = await withContext(
  ///   Dispatchers.isolate,
  ///   (it) => sha256.convert(bytes),
  /// );
  /// ```
  static const CoroutineDispatcher isolate = IsolateDispatcher();
}
