/*
 * Copyright 2026 Davils
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:essentia_coroutines/src/deferred/completable_deferred_impl.dart';
import 'package:essentia_coroutines/src/deferred/deferred.dart';
import 'package:essentia_coroutines/src/job/job.dart';

/// A deferred that is completed by hand.
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

  /// Completes the deferred with [value].
  ///
  /// Returns `true` when this call completed it, `false` when it was
  /// complete or cancelled already.
  bool complete(T value);

  /// Fails the deferred with [exception].
  ///
  /// Returns `true` when this call failed it, `false` when it was complete
  /// or cancelled already.
  bool completeExceptionally(Object exception, [StackTrace? stackTrace]);
}
