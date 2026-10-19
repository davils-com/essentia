/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/src/context/coroutine_context.dart';
import 'package:essentia_coroutines/src/scope/coroutine_scope.dart';

/// The scope of work that belongs to nobody.
///
/// Coroutines started in it have no parent, so nothing cancels or waits
/// for them. Prefer a scope owned by the component the work belongs to.
final class GlobalScope implements CoroutineScope {
  /// Creates the scope; there is one, [instance].
  const GlobalScope._();

  /// The global scope.
  static const instance = GlobalScope._();

  /// The empty context.
  @override
  CoroutineContext get coroutineContext => CoroutineContext.empty;

  /// Names the scope.
  @override
  String toString() => 'GlobalScope';
}
