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
import 'package:essentia_coroutines/src/context/coroutine_context.dart';
import 'package:essentia_coroutines/src/context/coroutine_context_element.dart';
import 'package:essentia_coroutines/src/context/coroutine_context_key.dart';

/// The context contract of a single element.
///
/// An element that mixes this in only has to name its
/// [CoroutineContextElement.contextKey].
mixin AbstractCoroutineContextElement implements CoroutineContextElement {
  /// Answers this element when it is stored under [key].
  ///
  /// Returns this element, or `null` for any other key.
  @override
  E? get<E extends CoroutineContextElement>(CoroutineContextKey<E> key) {
    final CoroutineContextElement self = this;
    if (identical(contextKey, key) && self is E) {
      return self;
    }
    return null;
  }

  /// Folds this single element into [initial].
  ///
  /// Returns the result of [operation].
  @override
  R fold<R>(
    R initial,
    R Function(R accumulator, CoroutineContextElement element) operation,
  ) => operation(initial, this);

  /// Combines this element with [other].
  ///
  /// Returns the combined context.
  @override
  CoroutineContext operator +(CoroutineContext other) =>
      combineContexts(this, other);

  /// Removes this element when it is stored under [key].
  ///
  /// Returns the empty context, or this element for any other key.
  @override
  CoroutineContext minusKey(CoroutineContextKey<CoroutineContextElement> key) {
    if (identical(contextKey, key)) {
      return CoroutineContext.empty;
    }
    return this;
  }
}
