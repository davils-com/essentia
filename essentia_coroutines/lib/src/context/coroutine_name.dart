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

import 'package:essentia_coroutines/src/context/abstract_coroutine_context_element.dart';
import 'package:essentia_coroutines/src/context/coroutine_context_key.dart';
import 'package:meta/meta.dart';

/// The name of a coroutine, for diagnostics.
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
