/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
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
