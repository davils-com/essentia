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

import 'package:essentia_core/src/collection/attribute_key.dart';

/// A map of typed values, each under its [AttributeKey]: what a request, a call
/// or a pipeline carries for the plugins that work on it.
///
/// ```dart
/// const retries = AttributeKey<int>('Retries');
/// final attributes = Attributes()..put(retries, 3);
/// final int count = attributes.get(retries);
/// final int? none = attributes.getOrNull(const AttributeKey<int>('Other'));
/// ```
final class Attributes {
  /// Creates attributes without values.
  Attributes();

  /// The values by their keys, in the order they were put.
  final _values = <AttributeKey<Object>, Object>{};

  /// The keys of every value, in the order they were put.
  List<AttributeKey<Object>> get allKeys =>
      List<AttributeKey<Object>>.unmodifiable(_values.keys);

  /// Whether a value is stored under [key].
  ///
  /// Returns `true` when one is.
  bool contains(AttributeKey<Object> key) => _values.containsKey(key);

  /// The value under [key].
  ///
  /// Returns the value.
  ///
  /// Throws a [StateError] when no value is stored under [key].
  T get<T extends Object>(AttributeKey<T> key) {
    final T? value = getOrNull(key);
    if (value == null) {
      throw StateError('No instance for key $key');
    }
    return value;
  }

  /// The value under [key], if there is one.
  ///
  /// Returns the value, or `null`.
  T? getOrNull<T extends Object>(AttributeKey<T> key) => _values[key] as T?;

  /// Stores [value] under [key], replacing the value stored there.
  ///
  /// Throws an [ArgumentError] when [value] is not of the type of [key],
  /// which only a key cast to a wider type lets through the compiler.
  void put<T extends Object>(AttributeKey<T> key, T value) {
    if (!key.accepts(value)) {
      throw ArgumentError.value(
        value.runtimeType,
        'value',
        'is no value of the type of $key, ${key.type}',
      );
    }
    _values[key] = value;
  }

  /// Removes the value under [key], if there is one.
  void remove<T extends Object>(AttributeKey<T> key) {
    _values.remove(key);
  }

  /// Removes the value under [key] and hands it out.
  ///
  /// Returns the value.
  ///
  /// Throws a [StateError] when no value is stored under [key].
  T take<T extends Object>(AttributeKey<T> key) {
    final T value = get(key);
    _values.remove(key);
    return value;
  }

  /// Removes the value under [key], if there is one, and hands it out.
  ///
  /// Returns the value, or `null`.
  T? takeOrNull<T extends Object>(AttributeKey<T> key) {
    final T? value = getOrNull(key);
    _values.remove(key);
    return value;
  }

  /// The value under [key], which [create] makes and stores when there is
  /// none.
  ///
  /// Returns the stored or the new value.
  T computeIfAbsent<T extends Object>(
    AttributeKey<T> key,
    T Function() create,
  ) {
    final T? existing = getOrNull(key);
    if (existing != null) {
      return existing;
    }
    final T created = create();
    put(key, created);
    return created;
  }

  /// Stores every value of [other] under its key here, replacing the values
  /// stored there.
  void putAll(Attributes other) {
    _values.addAll(other._values);
  }
}
