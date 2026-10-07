/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/coroutines/coroutine_context.dart';
import 'package:essentia/src/coroutines/coroutine_context_element.dart';
import 'package:essentia/src/coroutines/coroutine_context_key.dart';
import 'package:essentia/src/coroutines/function_exception_handler.dart';

/// Where a coroutine reports a failure nobody else handles, Kotlin's
/// `CoroutineExceptionHandler`.
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
  /// Creates the handler that passes every failure to [handler].
  ///
  /// The stack trace is a Dart addition to Kotlin's contract.
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
