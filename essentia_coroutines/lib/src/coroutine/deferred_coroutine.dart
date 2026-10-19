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

import 'package:essentia_coroutines/src/coroutine/abstract_coroutine.dart';
import 'package:essentia_coroutines/src/deferred/deferred_mixin.dart';
import 'package:meta/meta.dart';

/// The coroutine `async` starts: its failure stays in it, for whoever
/// awaits it.
@internal
final class DeferredCoroutine<T> extends AbstractCoroutine<T>
    with DeferredMixin<T> {
  /// Creates the coroutine with [parentContext], [active] at once or
  /// started lazily.
  DeferredCoroutine(super.parentContext, {required super.active});

  /// Names the kind of coroutine.
  @override
  String get kind => 'DeferredCoroutine';
}
