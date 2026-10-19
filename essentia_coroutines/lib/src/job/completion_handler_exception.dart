/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';

/// Reports that a completion handler of a job threw.
///
/// The job and its other handlers are not affected; the failure is reported
/// where the job reports what nobody handles.
final class CompletionHandlerException implements Exception, Causal {
  /// Creates the exception for the [cause] a handler threw at
  /// [stackTrace].
  const CompletionHandlerException(this.cause, this.stackTrace);

  /// What the handler threw.
  @override
  final Object cause;

  /// Where the handler threw it.
  final StackTrace stackTrace;

  /// Where the handler threw [cause]: the [stackTrace].
  @override
  StackTrace get causeStackTrace => stackTrace;

  /// Renders the exception with its cause.
  @override
  String toString() =>
      'CompletionHandlerException: Exception in completion handler: $cause';
}
