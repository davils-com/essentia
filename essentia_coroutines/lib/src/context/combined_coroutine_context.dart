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

import 'package:essentia_coroutines/src/context/coroutine_context.dart';
import 'package:essentia_coroutines/src/context/coroutine_context_element.dart';
import 'package:essentia_coroutines/src/context/coroutine_context_key.dart';
import 'package:meta/meta.dart';

/// A context of any number of elements, kept in an unmodifiable map from
/// key to element in the order they were added.
@internal
final class CombinedCoroutineContext implements CoroutineContext {
  /// Creates the context of [_elements].
  const CombinedCoroutineContext(this._elements);

  /// The context without any element.
  static const empty = CombinedCoroutineContext(
    <CoroutineContextKey<CoroutineContextElement>, CoroutineContextElement>{},
  );

  /// The elements by key, in the order they were added.
  final Map<
    CoroutineContextKey<CoroutineContextElement>,
    CoroutineContextElement
  >
  _elements;

  /// Answers the element stored under [key].
  ///
  /// Returns the element, or `null` when there is none.
  @override
  E? get<E extends CoroutineContextElement>(CoroutineContextKey<E> key) {
    final CoroutineContextElement? element = _elements[key];
    if (element is E) {
      return element;
    }
    return null;
  }

  /// Folds the elements into [initial], in the order they were added.
  ///
  /// Returns the result of the last [operation].
  @override
  R fold<R>(
    R initial,
    R Function(R accumulator, CoroutineContextElement element) operation,
  ) {
    var accumulator = initial;
    for (final CoroutineContextElement element in _elements.values) {
      accumulator = operation(accumulator, element);
    }
    return accumulator;
  }

  /// Combines this context with [other].
  ///
  /// Returns the combined context.
  @override
  CoroutineContext operator +(CoroutineContext other) =>
      combineContexts(this, other);

  /// Removes the element stored under [key].
  ///
  /// Returns the context without it.
  @override
  CoroutineContext minusKey(CoroutineContextKey<CoroutineContextElement> key) {
    if (!_elements.containsKey(key)) {
      return this;
    }
    return contextOf(
      _elements.values.where((element) => !identical(element.contextKey, key)),
    );
  }

  /// Renders the elements.
  @override
  String toString() => '[${_elements.values.join(', ')}]';
}

/// Lists the elements of [context] in the order they were added.
///
/// Returns the elements.
@internal
List<CoroutineContextElement> elementsOf(CoroutineContext context) =>
    context.fold<List<CoroutineContextElement>>(
      <CoroutineContextElement>[],
      (elements, element) => elements..add(element),
    );

/// Combines [left] with [right], whose elements replace the ones of [left]
/// stored under the same key and move to the end.
///
/// Returns the combined context.
@internal
CoroutineContext combineContexts(
  CoroutineContext left,
  CoroutineContext right,
) {
  final List<CoroutineContextElement> added = elementsOf(right);
  if (added.isEmpty) {
    return left;
  }
  final List<CoroutineContextElement> kept = elementsOf(left);
  if (kept.isEmpty) {
    return right;
  }
  final elements =
      <CoroutineContextKey<CoroutineContextElement>, CoroutineContextElement>{};
  for (final element in <CoroutineContextElement>[...kept, ...added]) {
    elements
      ..remove(element.contextKey)
      ..[element.contextKey] = element;
  }
  return contextOf(elements.values);
}

/// The context holding exactly [elements].
///
/// Returns the empty context, the single element itself, or a combined
/// context.
@internal
CoroutineContext contextOf(Iterable<CoroutineContextElement> elements) {
  final List<CoroutineContextElement> all = elements.toList();
  if (all.isEmpty) {
    return CoroutineContext.empty;
  }
  if (all.length == 1) {
    return all.single;
  }
  return CombinedCoroutineContext(
    Map<
      CoroutineContextKey<CoroutineContextElement>,
      CoroutineContextElement
    >.unmodifiable(
      <CoroutineContextKey<CoroutineContextElement>, CoroutineContextElement>{
        for (final element in all) element.contextKey: element,
      },
    ),
  );
}
