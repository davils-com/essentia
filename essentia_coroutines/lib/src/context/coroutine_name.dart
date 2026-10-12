/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/src/context/abstract_coroutine_context_element.dart';
import 'package:essentia_coroutines/src/context/coroutine_context_key.dart';
import 'package:meta/meta.dart';

/// The name of a coroutine, for diagnostics, Kotlin's `CoroutineName`.
///
/// ```dart
/// scope.launch((it) => index(), context: const CoroutineName('indexer'));
/// ```
@immutable
final class CoroutineName with AbstractCoroutineContextElement {
  /// Creates the name [name].
  const CoroutineName(this.name);

  /// The key the name is stored under.
  static const key = CoroutineContextKey<CoroutineName>('CoroutineName');

  /// The name.
  final String name;

  /// The key the name is stored under.
  @override
  CoroutineContextKey<CoroutineName> get contextKey => key;

  /// Whether [other] is a name with the same text.
  @override
  bool operator ==(Object other) =>
      other is CoroutineName && other.name == name;

  /// The hash of the text.
  @override
  int get hashCode => name.hashCode;

  /// Renders the name.
  @override
  String toString() => 'CoroutineName($name)';
}
