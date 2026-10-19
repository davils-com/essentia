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

import 'package:essentia_coroutines/src/context/coroutine_context.dart';
import 'package:essentia_coroutines/src/context/coroutine_context_key.dart';

/// One element of a coroutine context, which is a context of its own.
///
/// An element names the [contextKey] it is stored under. Mixing in
/// `AbstractCoroutineContextElement` supplies the rest of the context
/// contract.
abstract interface class CoroutineContextElement implements CoroutineContext {
  /// The key this element is stored under.
  CoroutineContextKey<CoroutineContextElement> get contextKey;
}
