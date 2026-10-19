/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
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
