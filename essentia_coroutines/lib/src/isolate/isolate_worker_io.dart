/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';
import 'dart:isolate';

import 'package:essentia_core/essentia_core.dart';
import 'package:essentia_coroutines/src/context/coroutine_context.dart';
import 'package:essentia_coroutines/src/context/coroutine_context_element.dart';
import 'package:essentia_coroutines/src/context/coroutine_name.dart';
import 'package:essentia_coroutines/src/coroutine/coroutine_scope_builders.dart';
import 'package:essentia_coroutines/src/exception/cancellation_exception.dart';
import 'package:essentia_coroutines/src/isolate/isolate_body_not_sendable_error.dart';
import 'package:essentia_coroutines/src/isolate/isolate_transferable.dart';
import 'package:essentia_coroutines/src/job/job.dart';
import 'package:essentia_coroutines/src/principal/principal_element.dart';
import 'package:essentia_coroutines/src/scope/coroutine_scope.dart';
import 'package:meta/meta.dart';

/// The command that runs a body on a worker isolate.
const _run = 0;

/// The command that cancels the body a worker isolate runs.
const _cancel = 1;

/// The reply of a worker isolate whose body returned a value.
const _succeeded = 0;

/// The reply of a worker isolate whose body threw.
const _failed = 1;

/// The reply of a worker isolate whose body was cancelled.
const _cancelled = 2;

/// The reply of a worker isolate whose body returned a value it cannot
/// send back.
const _unsendableResult = 3;

/// A worker of `Dispatchers.isolate`: a persistent isolate that runs one
/// body at a time.
///
/// The isolate is spawned for the first body and then kept. A body is sent
/// with the elements of its context that cross - its name, its principal
/// and every [IsolateTransferable] - as far as they are sendable, and runs
/// there as a coroutine of its own; cancelling the job of the
/// caller cancels it there, and an isolate that does not stop within
/// [killGrace] is killed. An isolate that dies fails the body it ran with
/// a [RemoteError] and is not used again.
@internal
final class IsolateWorkerIo {
  /// Creates a worker that kills its isolate [killGrace] after a
  /// cancellation it ignores.
  IsolateWorkerIo({this.killGrace = const Duration(seconds: 1)});

  /// How long a cancelled body may take to stop before its isolate is
  /// killed.
  final Duration killGrace;

  /// The connection to the isolate, `null` before the first body and after
  /// the isolate died.
  Future<SendPort>? _connection;

  /// Completes with the port of the isolate once it said hello.
  Completer<SendPort>? _hello;

  /// The port the isolate replies to.
  RawReceivePort? _replies;

  /// The isolate, once spawned.
  Isolate? _isolate;

  /// The outcome of the body the isolate runs, if any.
  Completer<Object?>? _pending;

  /// Kills an isolate that ignores a cancellation.
  Timer? _grace;

  /// Whether the worker can run another body.
  bool get isAlive => _connection != null;

  /// Sends [block] to the isolate and waits for its outcome.
  ///
  /// Returns what [block] returns.
  ///
  /// Throws what [block] throws, an [IsolateBodyNotSendableError] if
  /// [block] or its result cannot be sent, a [CancellationException] if
  /// the job of [context] is cancelled, and a [RemoteError] if the isolate
  /// died while it ran [block].
  Future<T> run<T>(
    CoroutineContext context,
    FutureOr<T> Function(CoroutineScope it) block,
  ) async {
    final outcome = Completer<Object?>();
    _pending = outcome;
    _replies?.keepIsolateAlive = true;
    Disposable? registration;
    try {
      final SendPort commands = await (_connection ??= _spawn());
      _replies?.keepIsolateAlive = true;
      _send(commands, block, _sendableElements(context));
      final Job? job = context.get(Job.key);
      registration = job?.invokeOnCompletion(
        onCancelling: true,
        (cause) => _cancelBody(commands, job),
      );
      final Object? value = await outcome.future;
      return value as T;
    } finally {
      registration?.dispose();
      _grace?.cancel();
      _grace = null;
      _pending = null;
      _replies?.keepIsolateAlive = false;
    }
  }

  /// Kills the isolate.
  void shutDown() {
    _isolate?.kill(priority: Isolate.immediate);
    _forget();
  }

  /// Sends [block] with [elements], leaving out the elements that cannot be
  /// sent.
  ///
  /// Throws an [IsolateBodyNotSendableError] if [block] cannot be sent.
  void _send<T>(
    SendPort commands,
    FutureOr<T> Function(CoroutineScope it) block,
    List<CoroutineContextElement> elements,
  ) {
    try {
      commands.send((_run, block, elements));
      return;
    } on Object {
      try {
        commands.send((_run, block, _sendable(elements)));
      } on Object catch (error) {
        throw IsolateBodyNotSendableError.body(error);
      }
    }
  }

  /// Cancels the body on the isolate, killing it if it ignores the
  /// cancellation of [job] for longer than [killGrace].
  void _cancelBody(SendPort commands, Job job) {
    commands.send((_cancel, null, null));
    _grace ??= Zone.root.createTimer(killGrace, () {
      final Completer<Object?>? pending = _pending;
      _pending = null;
      shutDown();
      pending?.completeError(job.getCancellationException());
    });
  }

  /// Spawns the isolate and waits for it to send its port.
  ///
  /// Returns the port bodies are sent to.
  Future<SendPort> _spawn() async {
    final hello = Completer<SendPort>();
    final replies = RawReceivePort(_receive, 'Dispatchers.isolate');
    _replies = replies;
    _hello = hello;
    try {
      _isolate = await Isolate.spawn(
        _work,
        replies.sendPort,
        onExit: replies.sendPort,
        onError: replies.sendPort,
        debugName: 'Dispatchers.isolate',
      );
    } on Object {
      _forget();
      rethrow;
    }
    return hello.future;
  }

  /// Handles a [message] of the isolate: its port, the outcome of a body,
  /// an uncaught error or its exit.
  void _receive(Object? message) {
    if (message is SendPort) {
      _hello?.complete(message);
      return;
    }
    if (message case (final int kind, final Object? value, final Object? at)) {
      _settle(kind, value, at);
      return;
    }
    if (message case [final Object? error, final Object? stackTrace]) {
      _fail(RemoteError('$error', '$stackTrace'));
      _forget();
      return;
    }
    _fail(RemoteError('The worker isolate exited while it ran a body', ''));
    _forget();
  }

  /// Completes the pending body with the reply [kind], carrying [value]
  /// and the stack trace [at] of a failure.
  void _settle(int kind, Object? value, Object? at) {
    final Completer<Object?>? pending = _pending;
    _pending = null;
    if (pending == null) {
      return;
    }
    final StackTrace? stackTrace = at is StackTrace ? at : null;
    if (kind == _succeeded) {
      pending.complete(value);
      return;
    }
    if (kind == _unsendableResult) {
      pending.completeError(IsolateBodyNotSendableError.result());
      return;
    }
    if (kind == _cancelled) {
      pending.completeError(
        CancellationException(value is String ? value : null),
        stackTrace,
      );
      return;
    }
    pending.completeError(value!, stackTrace);
  }

  /// Fails the pending body, if there is one, with [error].
  void _fail(Object error) {
    final Completer<Object?>? pending = _pending;
    _pending = null;
    pending?.completeError(error);
  }

  /// Drops the connection, so the worker is not used again.
  void _forget() {
    _replies?.close();
    _replies = null;
    _hello = null;
    _isolate = null;
    _connection = null;
  }

  /// The elements of [context] that cross to the isolate: its name, its
  /// principal and every [IsolateTransferable], in the order of the
  /// context.
  ///
  /// Returns them.
  static List<CoroutineContextElement> _sendableElements(
    CoroutineContext context,
  ) => context.fold<List<CoroutineContextElement>>(
    <CoroutineContextElement>[],
    (elements, element) {
      if (element is CoroutineName ||
          element is PrincipalElement ||
          element is IsolateTransferable) {
        elements.add(element);
      }
      return elements;
    },
  );

  /// The elements of [elements] that a `SendPort` accepts, each tried on its
  /// own through a port that is closed again at once.
  ///
  /// Returns them, in their order.
  static List<CoroutineContextElement> _sendable(
    List<CoroutineContextElement> elements,
  ) {
    final probe = RawReceivePort(null, 'Dispatchers.isolate probe');
    try {
      return <CoroutineContextElement>[
        for (final element in elements)
          if (_accepts(probe.sendPort, element)) element,
      ];
    } finally {
      probe.close();
    }
  }

  /// Whether [port] accepts [element].
  ///
  /// Returns `true` when sending it did not throw.
  static bool _accepts(SendPort port, CoroutineContextElement element) {
    try {
      port.send(element);
      return true;
    } on Object {
      return false;
    }
  }
}

/// The entry point of a worker isolate: says hello with its own port, then
/// runs every body it receives and replies to [replies].
void _work(SendPort replies) {
  final commands = ReceivePort();
  CoroutineScope? running;
  replies.send(commands.sendPort);
  commands.listen((message) {
    if (message case (_cancel, _, _)) {
      running?.cancel();
      return;
    }
    if (message case (
      _run,
      final FutureOr<Object?> Function(CoroutineScope it) block,
      final List<Object?> elements,
    )) {
      final scope = CoroutineScope(
        elements.whereType<CoroutineContextElement>().fold(
              CoroutineContext.empty,
              (context, element) => context + element,
            ) +
            Job(),
      );
      running = scope;
      unawaited(_perform(scope, block, replies));
    }
  });
}

/// Runs [block] in [scope] and sends its outcome to [replies].
///
/// Returns a future that completes once the outcome was sent.
Future<void> _perform(
  CoroutineScope scope,
  FutureOr<Object?> Function(CoroutineScope it) block,
  SendPort replies,
) async {
  final Object? value;
  try {
    value = await scope.async(block);
  } on CancellationException catch (cause, stackTrace) {
    replies.send((_cancelled, cause.message, stackTrace));
    return;
  } on Object catch (error, stackTrace) {
    _sendFailure(replies, error, stackTrace);
    return;
  }
  try {
    replies.send((_succeeded, value, null));
  } on Object {
    replies.send((_unsendableResult, null, null));
  }
}

/// Sends the failure [error] with its [stackTrace] to [replies], as a
/// [RemoteError] carrying its text when the error itself is not sendable.
void _sendFailure(SendPort replies, Object error, StackTrace stackTrace) {
  try {
    replies.send((_failed, error, stackTrace));
  } on Object {
    replies.send((_failed, RemoteError('$error', '$stackTrace'), stackTrace));
  }
}
