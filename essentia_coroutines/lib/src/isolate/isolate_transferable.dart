/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/src/context/coroutine_context_element.dart';

/// Marks an element of a coroutine context that crosses to the worker
/// isolate of `Dispatchers.isolate` together with the body it runs.
///
/// Of a context only the `CoroutineName`, the `PrincipalElement` and the
/// elements implementing this interface are sent along; everything else
/// stays behind. The element is copied through a `SendPort`, so it and
/// everything it holds must be sendable. An element that turns out not to
/// be is left out, and the body runs without it.
///
/// ```dart
/// final class TenantElement
///     with AbstractCoroutineContextElement
///     implements IsolateTransferable {
///   const TenantElement(this.tenant);
///
///   static const key = CoroutineContextKey<TenantElement>('Tenant');
///
///   final String tenant;
///
///   @override
///   CoroutineContextKey<TenantElement> get contextKey => key;
/// }
/// ```
abstract interface class IsolateTransferable
    implements CoroutineContextElement {}
