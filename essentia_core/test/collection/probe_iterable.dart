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

/// An iterable that counts how often it is iterated, to prove that an
/// operation is lazy or reads its source only once.
final class ProbeIterable<T> extends Iterable<T> {
  /// Creates a probe handing out the elements of [_source].
  ProbeIterable(this._source);

  /// The elements handed out.
  final Iterable<T> _source;

  /// How often an iterator was requested so far.
  var iterations = 0;

  /// Hands out an iterator over the source and counts the request.
  @override
  Iterator<T> get iterator {
    iterations++;
    return _source.iterator;
  }

  /// Builds an iterable from this probe with [build] without reading it.
  ///
  /// Returns how often this probe was iterated meanwhile.
  int iterationsWhileBuilding(Iterable<Object?> Function(Iterable<T>) build) {
    build(this);
    return iterations;
  }

  /// Builds an iterable from this probe with [build] and reads all of it.
  ///
  /// Returns how often this probe was iterated meanwhile.
  int iterationsWhileConsuming(Iterable<Object?> Function(Iterable<T>) build) {
    build(this).toList();
    return iterations;
  }
}

/// The natural numbers from zero on, without end.
///
/// Returns them lazily.
Iterable<int> naturals() sync* {
  var value = 0;
  while (true) {
    yield value++;
  }
}
