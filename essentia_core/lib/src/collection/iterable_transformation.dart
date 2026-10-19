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

import 'package:meta/meta.dart';

/// Transforms the elements of an iterable: every transformation is lazy
/// and reads the source only as its own elements are requested.
extension IterableTransformation<T> on Iterable<T> {
  /// Transforms every element and leaves out the `null` results.
  ///
  /// Returns the results that are present, lazily.
  @useResult
  Iterable<R> mapNotNull<R extends Object>(R? Function(T element) transform) =>
      map(transform).nonNulls;

  /// Transforms every element together with its index and leaves out the
  /// `null` results.
  ///
  /// Returns the results that are present, lazily.
  @useResult
  Iterable<R> mapIndexedNotNull<R extends Object>(
    R? Function(int index, T element) transform,
  ) => indexed.map((entry) => transform(entry.$1, entry.$2)).nonNulls;

  /// Keeps the first occurrence of every element.
  ///
  /// Returns the distinct elements, lazily.
  @useResult
  Iterable<T> distinct() => distinctBy<T>((element) => element);

  /// Keeps the first element of every key [keyOf] computes.
  ///
  /// The keys seen are forgotten each time the result is iterated again.
  ///
  /// Returns the kept elements, lazily.
  @useResult
  Iterable<T> distinctBy<K>(K Function(T element) keyOf) sync* {
    final seen = <K>{};
    for (final element in this) {
      if (seen.add(keyOf(element))) {
        yield element;
      }
    }
  }

  /// Runs [action] on every element as it is passed on.
  ///
  /// Nothing runs before the elements are requested.
  ///
  /// Returns the elements, unchanged and lazily.
  @useResult
  Iterable<T> onEach(void Function(T element) action) => map((element) {
    action(element);
    return element;
  });

  /// Runs [action] on every element and its index as it is passed on.
  ///
  /// Returns the elements, unchanged and lazily.
  @useResult
  Iterable<T> onEachIndexed(void Function(int index, T element) action) =>
      indexed.map((entry) {
        action(entry.$1, entry.$2);
        return entry.$2;
      });

  /// Pairs every element with the element of [other] at the same
  /// position, up to the end of the shorter one.
  ///
  /// Returns the pairs, lazily.
  @useResult
  Iterable<(T, R)> zip<R>(Iterable<R> other) sync* {
    final Iterator<R> others = other.iterator;
    for (final element in this) {
      if (!others.moveNext()) {
        return;
      }
      yield (element, others.current);
    }
  }

  /// Appends [element] after the last element.
  ///
  /// Returns the extended elements, lazily.
  @useResult
  Iterable<T> plusElement(T element) => followedBy(<T>[element]);

  /// Leaves out the first occurrence of [element].
  ///
  /// Returns the remaining elements, lazily.
  @useResult
  Iterable<T> minusElement(T element) sync* {
    var removed = false;
    for (final candidate in this) {
      if (!removed && candidate == element) {
        removed = true;
        continue;
      }
      yield candidate;
    }
  }

  /// Leaves out every occurrence of each of [elements].
  ///
  /// Returns the remaining elements, lazily.
  @useResult
  Iterable<T> minusAll(Iterable<T> elements) sync* {
    final Set<T> excluded = elements.toSet();
    yield* where((element) => !excluded.contains(element));
  }

  /// Falls back to the elements [fallback] supplies when there are none.
  ///
  /// Returns these elements, or those of [fallback] if there are none,
  /// lazily.
  @useResult
  Iterable<T> ifEmpty(Iterable<T> Function() fallback) sync* {
    var empty = true;
    for (final element in this) {
      empty = false;
      yield element;
    }
    if (empty) {
      yield* fallback();
    }
  }
}
