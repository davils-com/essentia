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
import 'package:essentia_coroutines/src/context/coroutine_context_zone.dart';
import 'package:essentia_coroutines/src/context/coroutine_name.dart';
import 'package:essentia_coroutines/src/coroutine/coroutine_start.dart';
import 'package:essentia_coroutines/src/dispatcher/coroutine_dispatcher.dart';
import 'package:essentia_coroutines/src/dispatcher/dispatchers.dart';
import 'package:essentia_coroutines/src/dispatcher/remote_dispatcher.dart';
import 'package:essentia_coroutines/src/exception/exception_handling.dart';
import 'package:essentia_coroutines/src/job/completion_handler_exception.dart';
import 'package:essentia_coroutines/src/job/job.dart';
import 'package:essentia_coroutines/src/job/job_support.dart';
import 'package:essentia_coroutines/src/scope/coroutine_scope.dart';
import 'package:meta/meta.dart';

/// A job with a body that runs in a zone of its own carrying its context,
/// Kotlin's `AbstractCoroutine`.
///
/// The body is a function returning a value or a `Future`; the coroutine
/// is done with its body once that future completes, and complete once its
/// children are too.
@internal
abstract base class AbstractCoroutine<T> extends JobSupport
    implements CoroutineScope {
  /// Creates the coroutine as a child of the job of [parentContext], [active]
  /// at once or started lazily.
  AbstractCoroutine(this.parentContext, {required super.active}) {
    final CoroutineContext context = parentContext + this;
    _context = context;
    _zone = forkCoroutineZone(context);
    initParentJob(parentContext.get(Job.key));
  }

  /// The context the coroutine was started with, without itself.
  final CoroutineContext parentContext;

  /// The context of the coroutine: [parentContext] with itself as the job.
  CoroutineContext _context = CoroutineContext.empty;

  /// The zone the body runs in, carrying [coroutineContext].
  Zone _zone = Zone.root;

  /// What the body returned, `null` until it did.
  ({T value})? _outcome;

  /// The body of a lazily started coroutine, until it is started.
  FutureOr<T> Function(CoroutineScope it)? _lazyBody;

  /// The context of the coroutine, with itself as the job.
  @override
  CoroutineContext get coroutineContext => _context;

  /// The zone the body runs in.
  @protected
  Zone get zone => _zone;

  /// What the body returned, `null` until it did.
  @protected
  ({T value})? get outcome => _outcome;

  /// The name of the kind of coroutine, with its `CoroutineName`.
  @override
  String get debugName {
    final CoroutineName? name = _context.get(CoroutineName.key);
    if (name == null) {
      return kind;
    }
    return '$kind[${name.name}]';
  }

  /// The name of the kind of coroutine.
  @protected
  String get kind;

  /// Starts [block] the way [start] says.
  void startCoroutine(
    CoroutineStart start,
    FutureOr<T> Function(CoroutineScope it) block,
  ) {
    switch (start) {
      case CoroutineStart.defaultStart:
        _dispatch(block, atomic: false);
      case CoroutineStart.atomic:
        _dispatch(block, atomic: true);
      case CoroutineStart.undispatched:
        _runBody(block, atomic: true);
      case CoroutineStart.lazy:
        _lazyBody = block;
    }
  }

  /// Dispatches the body of a lazily started coroutine.
  @override
  void onStart() {
    final FutureOr<T> Function(CoroutineScope it)? body = _lazyBody;
    _lazyBody = null;
    if (body != null) {
      _dispatch(body, atomic: false);
    }
  }

  /// Reports a throwing completion handler to the context.
  @override
  void handleOnCompletionException(Object error, StackTrace stackTrace) =>
      handleCoroutineException(
        _context,
        CompletionHandlerException(error, stackTrace),
        stackTrace,
        zone: _zone,
      );

  /// Hands [block] to the dispatcher of the context.
  void _dispatch(
    FutureOr<T> Function(CoroutineScope it) block, {
    required bool atomic,
  }) {
    final CoroutineDispatcher dispatcher =
        _context.get(CoroutineDispatcher.key) ?? Dispatchers.main;
    if (dispatcher is RemoteDispatcher &&
        (dispatcher as RemoteDispatcher).remote) {
      _runRemote(dispatcher as RemoteDispatcher, block, atomic: atomic);
      return;
    }
    if (!dispatcher.isDispatchNeeded(_context)) {
      _runBody(block, atomic: atomic);
      return;
    }
    dispatcher.dispatch(_context, _zone, () => _runBody(block, atomic: atomic));
  }

  /// Runs [block] in the zone of the coroutine, unless the coroutine was
  /// cancelled before and the start is not [atomic].
  void _runBody(
    FutureOr<T> Function(CoroutineScope it) block, {
    required bool atomic,
  }) {
    if (!atomic && isCancelled) {
      completeBody();
      return;
    }
    _zone.run(() {
      final FutureOr<T> result;
      try {
        result = block(this);
      } on Object catch (error, stackTrace) {
        failBody(error, stackTrace);
        return;
      }
      if (result is Future<T>) {
        unawaited(result.then<void>(_succeeded, onError: failBody));
        return;
      }
      _succeeded(result);
    });
  }

  /// Runs [block] elsewhere through [dispatcher], unless the coroutine was
  /// cancelled before and the start is not [atomic].
  void _runRemote(
    RemoteDispatcher dispatcher,
    FutureOr<T> Function(CoroutineScope it) block, {
    required bool atomic,
  }) {
    if (!atomic && isCancelled) {
      completeBody();
      return;
    }
    _zone.run(() {
      final Future<T> body = dispatcher.execute(_context, block);
      unawaited(body.then<void>(_succeeded, onError: failBody));
    });
  }

  /// Records [value] and marks the body as done.
  void _succeeded(T value) {
    _outcome = (value: value);
    completeBody();
  }
}
