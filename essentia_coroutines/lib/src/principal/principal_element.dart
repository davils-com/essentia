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

import 'package:essentia_core/essentia_core.dart';
import 'package:essentia_coroutines/src/context/abstract_coroutine_context_element.dart';
import 'package:essentia_coroutines/src/context/coroutine_context_key.dart';
import 'package:meta/meta.dart';

/// The principal a coroutine works for, as an element of its context.
///
/// `runAsPrincipal` lays it over the current context; a coroutine started
/// in a scope takes the principal of the scope, so work that has to act for
/// a caller is started with it:
///
/// ```dart
/// scope.launch((it) => audit(), context: PrincipalElement(caller));
/// ```
@immutable
final class PrincipalElement with AbstractCoroutineContextElement {
  /// Creates the element carrying [principal].
  const PrincipalElement(this.principal);

  /// The key the principal is stored under.
  static const key = CoroutineContextKey<PrincipalElement>('Principal');

  /// The principal.
  final Principal principal;

  /// The key the principal is stored under.
  @override
  CoroutineContextKey<PrincipalElement> get contextKey => key;

  /// Renders the principal.
  @override
  String toString() => 'PrincipalElement($principal)';
}
