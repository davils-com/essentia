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
import 'package:essentia_coroutines/src/exception/exception_handling.dart';
import 'package:meta/meta.dart';

/// The coroutine `launch` starts: its failure, unless the parent takes it
/// over, is reported to the `CoroutineExceptionHandler` of its context.
@internal
final class StandaloneCoroutine extends AbstractCoroutine<void> {
  /// Creates the coroutine with [parentContext], [active] at once or
  /// started lazily.
  StandaloneCoroutine(super.parentContext, {required super.active});

  /// Names the kind of coroutine.
  @override
  String get kind => 'StandaloneCoroutine';

  /// Reports [error] through the context.
  ///
  /// Returns `true`.
  @override
  bool handleJobException(Object error, StackTrace stackTrace) {
    handleCoroutineException(coroutineContext, error, stackTrace, zone: zone);
    return true;
  }
}
