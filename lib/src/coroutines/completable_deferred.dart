/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/coroutines/completable_deferred_impl.dart';
import 'package:essentia/src/coroutines/deferred.dart';
import 'package:essentia/src/coroutines/job.dart';

/// A deferred that is completed by hand, Kotlin's `CompletableDeferred`.
///
/// It is the cancellable, job aware counterpart of a `Completer`.
///
/// ```dart
/// final reply = CompletableDeferred<String>();
/// channel.onReply(reply.complete);
/// final String text = await reply;
/// ```
abstract interface class CompletableDeferred<T> implements Deferred<T> {
  /// Creates an active deferred, a child of [parent] if given.
  factory CompletableDeferred([Job? parent]) = CompletableDeferredImpl<T>;

  /// Completes the deferred with [value], Kotlin's `complete`.
  ///
  /// Returns `true` when this call completed it, `false` when it was
  /// complete or cancelled already.
  bool complete(T value);

  /// Fails the deferred with [exception], Kotlin's `completeExceptionally`.
  ///
  /// Returns `true` when this call failed it, `false` when it was complete
  /// or cancelled already.
  bool completeExceptionally(Object exception, [StackTrace? stackTrace]);
}
