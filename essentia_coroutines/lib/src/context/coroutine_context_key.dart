/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/src/context/coroutine_context_element.dart';
import 'package:meta/meta.dart';

/// The key an element of a coroutine context is stored under, Kotlin's
/// `CoroutineContext.Key`.
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
