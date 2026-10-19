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

import 'dart:async';

import 'package:essentia_coroutines/src/context/coroutine_context.dart';
import 'package:essentia_coroutines/src/exception/cancellation_exception.dart';
import 'package:essentia_coroutines/src/exception/coroutine_exception_handler.dart';
import 'package:essentia_coroutines/src/exception/suppressed_exceptions.dart';

/// Reports a failure of a coroutine nobody else handles.
///
/// A [CancellationException] is never reported. Otherwise the
/// [CoroutineExceptionHandler] of [context] gets it; without one, or when
/// that handler throws as well, [zone] - the zone the coroutine was started
/// in, the current one unless given - reports it as uncaught.
void handleCoroutineException(
  CoroutineContext context,
  Object error,
  StackTrace stackTrace, {
  Zone? zone,
}) {
  if (error is CancellationException) {
    return;
  }
  final Zone reporting = zone ?? Zone.current;
  final CoroutineExceptionHandler? handler = context.get(
    CoroutineExceptionHandler.key,
  );
  if (handler == null) {
    reporting.handleUncaughtError(error, stackTrace);
    return;
  }
  try {
    handler.handleException(context, error, stackTrace);
  } on Object catch (handlerError, handlerStackTrace) {
    addSuppressed(handlerError, error);
    reporting.handleUncaughtError(handlerError, handlerStackTrace);
  }
}
