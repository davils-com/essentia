/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/coroutines/coroutine_context.dart';
import 'package:essentia/src/coroutines/coroutine_scope.dart';
import 'package:meta/meta.dart';

/// A scope that is nothing but its context.
@internal
final class ContextScope implements CoroutineScope {
  /// Creates the scope with [coroutineContext].
  const ContextScope(this.coroutineContext);

  /// The context of the scope.
  @override
  final CoroutineContext coroutineContext;

  /// Renders the context of the scope.
  @override
  String toString() => 'CoroutineScope(coroutineContext=$coroutineContext)';
}
