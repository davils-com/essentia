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

import 'dart:math';

import 'package:meta/meta.dart';

/// Picks an element of any iterable at random.
///
/// A list is sampled by index; any other iterable is read once, picking
/// each element with equal probability by reservoir sampling.
extension IterableSampling<T> on Iterable<T> {
  /// Picks an element at random, drawing from [source] or from a fresh
  /// [Random] without one.
  ///
  /// Returns the picked element.
  ///
  /// Throws a [StateError] if there are no elements.
  @useResult
  T random([Random? source]) =>
      (_pick(source ?? Random()) ??
              (throw StateError('Cannot pick from an empty iterable.')))
          .value;

  /// Picks an element at random, drawing from [source] or from a fresh
  /// [Random] without one.
  ///
  /// Returns the picked element, or `null` if there are no elements.
  @useResult
  T? randomOrNull([Random? source]) => _pick(source ?? Random())?.value;

  /// Picks an element with [source], wrapped so that a picked `null`
  /// element differs from no element at all.
  ///
  /// Returns the picked element, or `null` if there are no elements.
  ({T value})? _pick(Random source) {
    final elements = this;
    if (elements is List<T>) {
      return elements.isEmpty
          ? null
          : (value: elements[source.nextInt(elements.length)]);
    }
    ({T value})? picked;
    var seen = 0;
    for (final element in elements) {
      if (source.nextInt(++seen) == 0) {
        picked = (value: element);
      }
    }
    return picked;
  }
}
