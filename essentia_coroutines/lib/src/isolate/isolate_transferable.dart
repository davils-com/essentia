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
