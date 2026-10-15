/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:collection';

/// A map whose keys compare without regard to case, Ktor's
/// `CaseInsensitiveMap`: what holds the headers of an HTTP message.
///
/// A key keeps the spelling it was first stored with; storing a value under
/// another spelling of it replaces the value and keeps the spelling, as in
/// Ktor. Unlike Ktor's, the map keeps the order its keys were first stored
/// in.
///
/// ```dart
/// final headers = CaseInsensitiveMap<String>()..['Content-Type'] = 'text/plain';
/// final String? type = headers['content-type'];
/// ```
final class CaseInsensitiveMap<V> extends MapBase<String, V> {
  /// Creates an empty map.
  CaseInsensitiveMap();

  /// Creates a map of the entries of [other], in its order; of keys that
  /// differ only in case, the first spelling and the last value win.
  CaseInsensitiveMap.of(Map<String, V> other) {
    addAll(other);
  }

  /// The entries, each with the spelling its key was first stored with, by
  /// the lower case form of the key.
  final _entries = <String, MapEntry<String, V>>{};

  /// The keys, each in the spelling it was first stored with.
  @override
  Iterable<String> get keys => _entries.values.map((entry) => entry.key);

  /// The number of entries.
  @override
  int get length => _entries.length;

  /// The value under [key], in any case.
  ///
  /// Returns it, or `null` when [key] is no string or is missing.
  @override
  V? operator [](Object? key) {
    if (key is! String) {
      return null;
    }
    return _entries[_fold(key)]?.value;
  }

  /// Stores [value] under [key], keeping the spelling of a key that
  /// differs from it only in case.
  @override
  void operator []=(String key, V value) {
    final String folded = _fold(key);
    final MapEntry<String, V>? existing = _entries[folded];
    _entries[folded] = MapEntry<String, V>(existing?.key ?? key, value);
  }

  /// Whether a value is stored under [key], in any case.
  ///
  /// Returns `true` when one is.
  @override
  bool containsKey(Object? key) =>
      key is String && _entries.containsKey(_fold(key));

  /// Removes the entry of [key], in any case.
  ///
  /// Returns the value it held, or `null`.
  @override
  V? remove(Object? key) {
    if (key is! String) {
      return null;
    }
    return _entries.remove(_fold(key))?.value;
  }

  /// Removes every entry.
  @override
  void clear() {
    _entries.clear();
  }

  /// The form of [key] two spellings of it share.
  ///
  /// Returns the key in lower case.
  static String _fold(String key) => key.toLowerCase();
}
