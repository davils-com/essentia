/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
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
