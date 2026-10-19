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
import 'package:essentia_coroutines/src/context/coroutine_context_element.dart';
import 'package:essentia_coroutines/src/context/coroutine_context_key.dart';
import 'package:essentia_coroutines/src/exception/function_exception_handler.dart';

/// Where a coroutine reports a failure nobody else handles.
///
/// A coroutine started with `launch` that fails, and whose parent does not
/// take the failure over, reports it here; without a handler it goes to the
/// zone the coroutine was started in. `async` keeps its failure in its
/// `Deferred` and never reports it here.
///
/// ```dart
/// final scope = CoroutineScope(
///   SupervisorJob() +
///       CoroutineExceptionHandler((context, error, stackTrace) {
///         report(error, stackTrace);
///       }),
/// );
/// ```
abstract interface class CoroutineExceptionHandler
    implements CoroutineContextElement {
  /// Creates the handler that passes every failure to [handler], together with
  /// its stack trace.
  factory CoroutineExceptionHandler(
    void Function(CoroutineContext context, Object error, StackTrace stackTrace)
    handler,
  ) = FunctionExceptionHandler;

  /// The key the handler is stored under.
  static const key = CoroutineContextKey<CoroutineExceptionHandler>(
    'CoroutineExceptionHandler',
  );

  /// Handles [error], thrown at [stackTrace] by the coroutine running with
  /// [context].
  void handleException(
    CoroutineContext context,
    Object error,
    StackTrace stackTrace,
  );
}
