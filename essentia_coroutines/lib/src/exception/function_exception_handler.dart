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

import 'package:essentia_coroutines/src/context/abstract_coroutine_context_element.dart';
import 'package:essentia_coroutines/src/context/coroutine_context.dart';
import 'package:essentia_coroutines/src/context/coroutine_context_key.dart';
import 'package:essentia_coroutines/src/exception/coroutine_exception_handler.dart';
import 'package:meta/meta.dart';

/// A [CoroutineExceptionHandler] that passes every failure to a function.
@internal
final class FunctionExceptionHandler
    with AbstractCoroutineContextElement
    implements CoroutineExceptionHandler {
  /// Creates the handler calling [_handler].
  FunctionExceptionHandler(this._handler);

  /// What handles a failure.
  final void Function(
    CoroutineContext context,
    Object error,
    StackTrace stackTrace,
  )
  _handler;

  /// The key of every exception handler.
  @override
  CoroutineContextKey<CoroutineExceptionHandler> get contextKey =>
      CoroutineExceptionHandler.key;

  /// Passes [error] to the function.
  @override
  void handleException(
    CoroutineContext context,
    Object error,
    StackTrace stackTrace,
  ) => _handler(context, error, stackTrace);

  /// Names the handler.
  @override
  String toString() => 'CoroutineExceptionHandler';
}
