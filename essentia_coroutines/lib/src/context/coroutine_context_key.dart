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

import 'package:essentia_coroutines/src/context/coroutine_context_element.dart';
import 'package:meta/meta.dart';

/// The key an element of a coroutine context is stored under.
///
/// Every kind of element declares one constant key, `Job.key`,
/// `CoroutineName.key` and so on, and a context holds at most one element
/// per key. Keys compare by identity; a constant key is canonical, so the
/// same declaration always yields the same key.
@immutable
final class CoroutineContextKey<E extends CoroutineContextElement> {
  /// Creates the key, rendered as [name].
  const CoroutineContextKey(this.name);

  /// The name the key is rendered with.
  final String name;

  /// Renders the name of the key.
  @override
  String toString() => name;
}
