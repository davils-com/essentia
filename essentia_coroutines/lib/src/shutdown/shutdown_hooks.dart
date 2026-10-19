/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia_core/essentia_core.dart';
import 'package:essentia_coroutines/src/scheduler/scheduled_task.dart';
import 'package:essentia_coroutines/src/scheduler/scheduler.dart';
import 'package:essentia_coroutines/src/shutdown/shutdown_hook.dart';
import 'package:essentia_coroutines/src/shutdown/shutdown_host.dart';
import 'package:essentia_coroutines/src/shutdown/shutdown_registration.dart';
import 'package:essentia_coroutines/src/shutdown/shutdown_signal.dart';

/// The work a program does when its host signals its end: its shutdown hooks.
///
/// Watching a signal replaces what a process does on it by default, so two
/// components that each watched `SIGTERM` and each ended the process when
/// done would cut each other short. [process] is the one place every
/// component of a program adds its hook to, and the one place that ends
/// the program, once all of them are done.
///
/// ```dart
/// final Disposable hook = ShutdownHooks.process.add((signal) async {
///   if (signal.endsProgram) {
///     await server.stop();
///   }
/// });
/// ```
///
/// - **One watch.** The signals are watched while at least one hook is
///   added; removing the last restores the default of the host.
/// - **In reverse order.** On a signal the hooks run one after the other,
///   the last added first, as resources are released in the reverse order
///   of their acquisition: a server started after logging stops before
///   logging flushes. A hook added while they run does not run.
/// - **Bounded.** A signal that ends the program gives the hooks [timeout]
///   on the [Scheduler] together, then ends the program with the exit code
///   of the signal, whether they are done or not. A second such signal
///   while they run ends the program at once.
/// - **Isolated.** A failing hook does not stop the others: its failure goes
///   to the uncaught-error handler of the current zone.
final class ShutdownHooks {
  /// Creates hooks that watch the signals of `host`, giving the hooks
  /// [timeout] on `scheduler` before the program ends.
  ShutdownHooks({
    this._host = ShutdownHost.system,
    this.timeout = defaultTimeout,
    this._scheduler = Scheduler.system,
  });

  /// The hooks of the running program, on [ShutdownHost.system].
  static final process = ShutdownHooks();

  /// The time the hooks get by default: 25 seconds, below the 30 seconds
  /// after which a container runtime usually kills a process that
  /// ignored `SIGTERM`.
  static const defaultTimeout = Duration(seconds: 25);

  /// The time the hooks get together once a signal ends the program.
  final Duration timeout;

  /// The host whose signals are watched.
  final ShutdownHost _host;

  /// Where [timeout] is measured.
  final Scheduler _scheduler;

  /// The hooks, in the order they were added.
  final _hooks = <ShutdownRegistration>[];

  /// The watch of the signals, while there are hooks.
  StreamSubscription<ShutdownSignal>? _watch;

  /// The end of the program, once a signal started it.
  Future<void>? _ending;

  /// Whether a signal that ends the program arrived.
  bool get isShuttingDown => _ending != null;

  /// The number of hooks added and not removed.
  int get length => _hooks.length;

  /// Adds [hook], starting to watch the signals of the host if it is the
  /// first.
  ///
  /// Returns the handle that removes [hook].
  Disposable add(ShutdownHook hook) {
    final registration = ShutdownRegistration(hook, _remove);
    _hooks.add(registration);
    _watch ??= _host.watch().listen(_onSignal);
    return registration;
  }

  /// Runs the hooks for [signal] as if the host had sent it: what a
  /// shutdown URL or a supervisor of the program calls.
  ///
  /// Returns a future that completes once the hooks ran; for a signal that
  /// ends the program, once the program was told to end, which on a real
  /// host never happens.
  Future<void> shutdown(ShutdownSignal signal) {
    final int? code = signal.exitCode;
    if (code == null) {
      return _runHooks(signal);
    }
    final Future<void>? ending = _ending;
    if (ending != null) {
      _host.exit(code);
      return ending;
    }
    return _ending = _end(signal, code);
  }

  /// Runs the hooks for [signal] within [timeout], then ends the program
  /// with [code].
  Future<void> _end(ShutdownSignal signal, int code) async {
    final done = Completer<void>();
    final ScheduledTask deadline = _scheduler.schedule(timeout, () {
      if (!done.isCompleted) {
        done.complete();
      }
    });
    unawaited(
      _runHooks(signal).whenComplete(() {
        if (!done.isCompleted) {
          done.complete();
        }
      }),
    );
    await done.future;
    deadline.cancel();
    _host.exit(code);
  }

  /// Runs the hooks for [signal], the last added first.
  Future<void> _runHooks(ShutdownSignal signal) async {
    for (final ShutdownRegistration registration in _hooks.reversed.toList()) {
      if (!_hooks.contains(registration)) {
        continue;
      }
      try {
        await registration.hook(signal);
      } on Object catch (error, stackTrace) {
        Zone.current.handleUncaughtError(error, stackTrace);
      }
    }
  }

  /// Runs the hooks for a [signal] of the host.
  void _onSignal(ShutdownSignal signal) => unawaited(shutdown(signal));

  /// Removes [registration], and stops watching once no hook is left and
  /// the program is not ending.
  void _remove(ShutdownRegistration registration) {
    _hooks.remove(registration);
    if (_hooks.isNotEmpty || _ending != null) {
      return;
    }
    unawaited(_watch?.cancel());
    _watch = null;
  }
}
