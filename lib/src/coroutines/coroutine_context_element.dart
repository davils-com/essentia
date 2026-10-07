/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/coroutines/coroutine_context.dart';
import 'package:essentia/src/coroutines/coroutine_context_key.dart';

/// One element of a coroutine context, which is a context of its own,
/// Kotlin's `CoroutineContext.Element`.
///
/// An element names the [contextKey] it is stored under. Mixing in
/// `AbstractCoroutineContextElement` supplies the rest of the context
/// contract.
abstract interface class CoroutineContextElement implements CoroutineContext {
  /// The key this element is stored under, Kotlin's `Element.key`.
  CoroutineContextKey<CoroutineContextElement> get contextKey;
}
