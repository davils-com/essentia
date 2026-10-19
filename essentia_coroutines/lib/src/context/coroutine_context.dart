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

import 'package:essentia_coroutines/src/context/combined_coroutine_context.dart';
import 'package:essentia_coroutines/src/context/coroutine_context_element.dart';
import 'package:essentia_coroutines/src/context/coroutine_context_key.dart';

/// An immutable set of elements, at most one per key, that a coroutine runs
/// with.
///
/// The elements say which job the work belongs to, what it is called, how
/// its unhandled failures are reported, where it is dispatched, which
/// scheduler it waits on and which principal it acts for. The context of the
/// running code is read with `currentCoroutineContext()`; it travels in a
/// `Zone`, so it reaches every `await` of the work.
///
/// ```dart
/// final CoroutineContext context =
///     const CoroutineName('indexer') + CoroutineExceptionHandler(report);
/// context.get(CoroutineName.key)?.name; // 'indexer'
/// ```
abstract interface class CoroutineContext {
  /// The context without any element.
  static const CoroutineContext empty = CombinedCoroutineContext.empty;

  /// The element stored under [key].
  ///
  /// Returns the element, or `null` when the context holds none under
  /// [key].
  E? get<E extends CoroutineContextElement>(CoroutineContextKey<E> key);

  /// Folds the elements into [initial], in the order they were added.
  ///
  /// Returns the result of the last [operation].
  R fold<R>(
    R initial,
    R Function(R accumulator, CoroutineContextElement element) operation,
  );

  /// Combines this context with [other], whose elements replace the ones of
  /// this context stored under the same key.
  ///
  /// Returns the combined context.
  CoroutineContext operator +(CoroutineContext other);

  /// Removes the element stored under [key].
  ///
  /// Returns the context without it, or this context when it holds none.
  CoroutineContext minusKey(CoroutineContextKey<CoroutineContextElement> key);
}
