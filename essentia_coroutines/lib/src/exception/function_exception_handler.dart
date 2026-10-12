/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
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
