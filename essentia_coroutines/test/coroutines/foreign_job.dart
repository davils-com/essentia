/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';
import 'package:essentia_coroutines/essentia_coroutines.dart';

import 'foreign_removal.dart';

/// A job of another library, which only offers the [Job] interface.
final class ForeignJob with AbstractCoroutineContextElement implements Job {
  /// The registered handlers with whether they run on cancelling.
  final _handlers = <(CompletionHandler, bool)>[];

  /// How many handlers were removed again.
  var disposed = 0;

  /// The cause it was cancelled with.
  Object? _cause;

  /// See [AbstractCoroutineContextElement.contextKey].
  @override
  CoroutineContextKey<Job> get contextKey => Job.key;

  /// See [Job.parent].
  @override
  Job? get parent => null;

  /// See [Job.isActive].
  @override
  bool get isActive => _cause == null;

  /// See [Job.isCompleted].
  @override
  bool get isCompleted => false;

  /// See [Job.isCancelled].
  @override
  bool get isCancelled => _cause != null;

  /// See [Job.children].
  @override
  Iterable<Job> get children => const <Job>[];

  /// See [Job.start].
  @override
  bool start() => false;

  /// See [Job.cancel].
  @override
  void cancel([CancellationException? cause]) => fire(cause ?? 'cancelled');

  /// Runs every handler with [cause]; a `null` cause completes the job.
  void fire(Object? cause) {
    _cause = cause;
    for (final (CompletionHandler handler, bool _) in _handlers.toList()) {
      handler(cause);
    }
  }

  /// See [Job.getCancellationException].
  @override
  CancellationException getCancellationException() =>
      const CancellationException('foreign');

  /// See [Job.join].
  @override
  Future<void> join() => Future<void>.value();

  /// See [Job.invokeOnCompletion].
  @override
  Disposable invokeOnCompletion(
    CompletionHandler handler, {
    bool onCancelling = false,
  }) {
    final registration = (handler, onCancelling);
    _handlers.add(registration);
    return ForeignRemoval(() {
      disposed++;
      _handlers.remove(registration);
    });
  }
}
