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
import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:essentia_coroutines/testing.dart';
import 'package:test/test.dart';

/// Covers `ShutdownHooks` on a `FakeShutdownHost` and virtual time.
void main() {
  group('watching', () {
    test('watches the host once the first hook is added', () {
      final host = FakeShutdownHost();
      final hooks = ShutdownHooks(host: host);

      expect(host.isWatched, isFalse);

      hooks
        ..add((signal) {})
        ..add((signal) {});

      expect(host.isWatched, isTrue);
      expect(hooks.length, 2);
    });

    test('restores the default of the host once the last hook is removed', () {
      final host = FakeShutdownHost();
      final hooks = ShutdownHooks(host: host);
      final Disposable first = hooks.add((signal) {});
      final Disposable second = hooks.add((signal) {});

      first.dispose();
      expect(host.isWatched, isTrue);

      second
        ..dispose()
        ..dispose();
      expect(host.isWatched, isFalse);
      expect(hooks.length, 0);

      host.raise(ShutdownSignal.terminate);
      expect(host.exits, <int>[143]);
    });

    test('watches again once a hook is added after the last was removed', () {
      final host = FakeShutdownHost();
      final hooks = ShutdownHooks(host: host);

      hooks.add((signal) {}).dispose();
      hooks.add((signal) {});

      expect(host.isWatched, isTrue);
    });
  });

  group('a signal that ends the program', () {
    for (final (ShutdownSignal signal, int code) in <(ShutdownSignal, int)>[
      (ShutdownSignal.interrupt, 130),
      (ShutdownSignal.terminate, 143),
    ]) {
      test(
        'runs the hooks, the last added first, then exits with $code',
        () async {
          final host = FakeShutdownHost();
          final hooks = ShutdownHooks(host: host);
          final ran = <String>[];
          hooks
            ..add((signal) => ran.add('logging ${signal.name}'))
            ..add((signal) async {
              await Future<void>.delayed(Duration.zero);
              ran.add('server ${signal.name}');
            });

          host.raise(signal);
          expect(hooks.isShuttingDown, isTrue);
          await pumpEventQueue();

          expect(ran, <String>[
            'server ${signal.name}',
            'logging ${signal.name}',
          ]);
          expect(host.exits, <int>[code]);
        },
      );
    }

    test('skips a hook removed by a hook that ran before it', () async {
      final host = FakeShutdownHost();
      final hooks = ShutdownHooks(host: host);
      final ran = <String>[];
      final Disposable first = hooks.add((signal) => ran.add('first'));
      hooks.add((signal) {
        ran.add('second');
        first.dispose();
      });

      host.raise(ShutdownSignal.terminate);
      await pumpEventQueue();

      expect(ran, <String>['second']);
      expect(host.exits, <int>[143]);
    });

    test('does not run a hook added while the hooks run', () async {
      final host = FakeShutdownHost();
      final hooks = ShutdownHooks(host: host);
      final ran = <String>[];
      hooks.add((signal) {
        ran.add('present');
        hooks.add((signal) => ran.add('late'));
      });

      host.raise(ShutdownSignal.terminate);
      await pumpEventQueue();

      expect(ran, <String>['present']);
    });

    test(
      'runs the other hooks when one fails and reports the failure',
      () async {
        final host = FakeShutdownHost();
        final ran = <String>[];
        final failures = <Object>[];

        await runZonedGuarded(() async {
          ShutdownHooks(host: host)
            ..add((signal) => ran.add('first'))
            ..add((signal) => throw StateError('hook failed'))
            ..add((signal) => ran.add('third'));
          host.raise(ShutdownSignal.terminate);
          await pumpEventQueue();
        }, (error, stackTrace) => failures.add(error));

        expect(ran, <String>['third', 'first']);
        expect(failures, <Matcher>[isStateError]);
        expect(host.exits, <int>[143]);
      },
    );

    test(
      'exits once the timeout passed, whether the hooks are done or not',
      () async {
        final scheduler = TestScheduler();
        final host = FakeShutdownHost();
        final stuck = Completer<void>();
        final hooks = ShutdownHooks(
          host: host,
          timeout: const Duration(seconds: 10),
          scheduler: scheduler,
        )..add((signal) => stuck.future);

        host.raise(ShutdownSignal.terminate);
        await scheduler.advanceTimeBy(const Duration(seconds: 9));
        await pumpEventQueue();
        expect(host.exits, isEmpty);

        await scheduler.advanceTimeBy(const Duration(seconds: 1));
        await pumpEventQueue();
        expect(host.exits, <int>[143]);
        expect(hooks.isShuttingDown, isTrue);
        stuck.complete();
      },
    );

    test('a second signal while the hooks run exits at once', () async {
      final host = FakeShutdownHost();
      final stuck = Completer<void>();
      final hooks = ShutdownHooks(host: host)..add((signal) => stuck.future);

      host.raise(ShutdownSignal.terminate);
      await pumpEventQueue();
      host.raise(ShutdownSignal.interrupt);

      expect(host.exits, <int>[130]);

      stuck.complete();
      await pumpEventQueue();
      expect(host.exits, <int>[130, 143]);
      expect(hooks.isShuttingDown, isTrue);
    });

    test('keeps watching when the hooks are removed while they run', () async {
      final host = FakeShutdownHost();
      final hooks = ShutdownHooks(host: host);
      final stuck = Completer<void>();
      final Disposable hook = hooks.add((signal) => stuck.future);

      host.raise(ShutdownSignal.terminate);
      await pumpEventQueue();
      hook.dispose();

      expect(host.isWatched, isTrue);
      stuck.complete();
    });
  });

  group('a signal that does not end the program', () {
    test('runs the hooks and leaves the program running', () async {
      final host = FakeShutdownHost();
      final hooks = ShutdownHooks(host: host);
      final seen = <ShutdownSignal>[];
      hooks.add(seen.add);

      host
        ..raise(ShutdownSignal.pageHide)
        ..raise(ShutdownSignal.pageHide);
      await pumpEventQueue();

      expect(seen, <ShutdownSignal>[
        ShutdownSignal.pageHide,
        ShutdownSignal.pageHide,
      ]);
      expect(host.exits, isEmpty);
      expect(hooks.isShuttingDown, isFalse);
    });
  });

  group('shutdown', () {
    test('runs the hooks as a signal of the host would', () async {
      final host = FakeShutdownHost();
      final hooks = ShutdownHooks(host: host);
      final seen = <ShutdownSignal>[];
      hooks.add(seen.add);

      await hooks.shutdown(ShutdownSignal.terminate);

      expect(seen, <ShutdownSignal>[ShutdownSignal.terminate]);
      expect(host.exits, <int>[143]);
    });

    test('ends the program without hooks', () async {
      final host = FakeShutdownHost();

      await ShutdownHooks(host: host).shutdown(ShutdownSignal.interrupt);

      expect(host.exits, <int>[130]);
    });
  });

  test('the hooks of the process watch the system and wait 25 seconds', () {
    expect(ShutdownHooks.process, same(ShutdownHooks.process));
    expect(ShutdownHooks.process.timeout, const Duration(seconds: 25));
    expect(ShutdownHooks.defaultTimeout, const Duration(seconds: 25));
    expect(ShutdownHooks.process.length, 0);
  });

  test('the signals tell whether and with which code they end a program', () {
    expect(ShutdownSignal.interrupt.exitCode, 130);
    expect(ShutdownSignal.terminate.exitCode, 143);
    expect(ShutdownSignal.pageHide.exitCode, isNull);
    expect(ShutdownSignal.interrupt.endsProgram, isTrue);
    expect(ShutdownSignal.pageHide.endsProgram, isFalse);
  });
}
