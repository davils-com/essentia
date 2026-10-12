/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';
import 'package:essentia_coroutines/src/context/abstract_coroutine_context_element.dart';
import 'package:essentia_coroutines/src/context/coroutine_context_key.dart';
import 'package:meta/meta.dart';

/// The principal a coroutine works for, as an element of its context, the
/// way Arc carries it in the coroutine context.
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
