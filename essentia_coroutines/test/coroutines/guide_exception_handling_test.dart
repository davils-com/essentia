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

import 'arithmetic_exception.dart';
import 'assertion_exception.dart';
import 'io_exception.dart';

/// The handler of the guide, logging what it gets into [log].
///
/// Returns the handler.
CoroutineExceptionHandler _handler(List<String> log) =>
    CoroutineExceptionHandler((context, exception, stackTrace) {
      final List<Object> suppressed = suppressedExceptionsOf(exception);
      log.add(
        'CoroutineExceptionHandler got ${exception.runtimeType}'
        '${suppressed.isEmpty ? '' : ' with suppressed '
                  '${suppressed.map((it) => it.runtimeType).toList()}'}',
      );
    });

/// What the first child of the guide prints once it is cancelled.
const _waiting =
    'Children are cancelled, but exception is not handled until all '
    'children terminate';

/// What the second child of the supervision example prints.
const _stillActive =
    'The first child is cancelled: true, but the second one is still active';

/// What the handler of the aggregation example prints.
const _aggregated =
    'CoroutineExceptionHandler got IoException with suppressed '
    '[ArithmeticException]';

/// Covers the examples of the kotlinx.coroutines guide "Coroutine
/// exceptions handling", ported line by line, with the output they print
/// as a golden log.
void main() {
  test(
    'exception propagation',
    () => runTest((it) async {
      final log = <String>[];
      final uncaught = <Object>[];
      await runZonedGuarded(() async {
        final Job job = GlobalScope.instance.launch((it) {
          log.add('Throwing exception from launch');
          throw RangeError('index');
        });
        await job.join();
        log.add('Joined failed job');
        final Deferred<void> deferred = GlobalScope.instance.async((it) {
          log.add('Throwing exception from async');
          throw ArithmeticException();
        });
        try {
          await deferred;
          log.add('Unreached');
        } on ArithmeticException {
          log.add('Caught ArithmeticException');
        }
      }, (error, stackTrace) => uncaught.add(error));

      expect(log, <String>[
        'Throwing exception from launch',
        'Joined failed job',
        'Throwing exception from async',
        'Caught ArithmeticException',
      ]);
      expect(uncaught, <Matcher>[isRangeError]);
    }),
  );

  test(
    'coroutine exception handler',
    () => runTest((it) async {
      final log = <String>[];
      final CoroutineExceptionHandler handler = _handler(log);
      final Job job = GlobalScope.instance.launch(
        (it) => throw AssertionException(),
        context: handler,
      );
      final Deferred<void> deferred = GlobalScope.instance.async(
        (it) => throw ArithmeticException(),
        context: handler,
      );
      await <Job>[job, deferred].joinAll();

      expect(log, <String>['CoroutineExceptionHandler got AssertionException']);
    }),
  );

  test(
    'cancellation and exceptions',
    () => runTest((it) async {
      final log = <String>[];
      final Job job = it.launch((it) async {
        final Job child = it.launch((it) async {
          try {
            await awaitCancellation();
          } finally {
            log.add('Child is cancelled');
          }
        });
        await yieldNow();
        log.add('Cancelling child');
        child.cancel();
        await child.join();
        await yieldNow();
        log.add('Parent is not cancelled');
      });
      await job.join();

      expect(log, <String>[
        'Cancelling child',
        'Child is cancelled',
        'Parent is not cancelled',
      ]);
    }),
  );

  test(
    'exception is handled once all children terminate',
    () => runTest((it) async {
      final log = <String>[];
      final Job job = GlobalScope.instance.launch((it) {
        it
          ..launch((it) async {
            try {
              await awaitCancellation();
            } finally {
              await withContext(NonCancellable.instance, (it) async {
                log.add(_waiting);
                await delay(100.milliseconds);
                log.add('The first child finished its non cancellable block');
              });
            }
          })
          ..launch((it) async {
            await delay(10.milliseconds);
            log.add('Second child throws an exception');
            throw ArithmeticException();
          });
      }, context: _handler(log));
      await job.join();

      expect(log, <String>[
        'Second child throws an exception',
        _waiting,
        'The first child finished its non cancellable block',
        'CoroutineExceptionHandler got ArithmeticException',
      ]);
    }),
  );

  test(
    'exceptions aggregation',
    () => runTest((it) async {
      final log = <String>[];
      final Job job = GlobalScope.instance.launch((it) async {
        it
          ..launch((it) async {
            try {
              await awaitCancellation();
            } on CancellationException {
              throw ArithmeticException();
            }
          })
          ..launch((it) async {
            await delay(100.milliseconds);
            throw IoException();
          });
        await awaitCancellation();
      }, context: _handler(log));
      await job.join();

      expect(log, <String>[_aggregated]);
    }),
  );

  test(
    'the original cause is handled after unwrapping',
    () => runTest((it) async {
      final log = <String>[];
      final Job job = GlobalScope.instance.launch((it) async {
        final Job innerJob = it.launch((it) {
          it.launch((it) {
            it.launch((it) => throw IoException());
          });
        });
        try {
          await innerJob.join();
        } on CancellationException {
          log.add('Rethrowing CancellationException with original cause');
          rethrow;
        }
      }, context: _handler(log));
      await job.join();

      expect(log, <String>[
        'Rethrowing CancellationException with original cause',
        'CoroutineExceptionHandler got IoException',
      ]);
    }),
  );

  test(
    'supervision job',
    () => runTest((it) async {
      final log = <String>[];
      final supervisor = SupervisorJob();
      final scope = CoroutineScope(it.coroutineContext + supervisor);
      final Job firstChild = scope.launch((it) {
        log.add('The first child is failing');
        throw AssertionException();
      }, context: CoroutineExceptionHandler((context, error, stackTrace) {}));
      final Job secondChild = scope.launch((it) async {
        await firstChild.join();
        log.add(
          'The first child is cancelled: ${firstChild.isCancelled}, but the '
          'second one is still active',
        );
        try {
          await awaitCancellation();
        } finally {
          log.add(
            'The second child is cancelled because the supervisor was '
            'cancelled',
          );
        }
      });
      await firstChild.join();
      await yieldNow();
      log.add('Cancelling the supervisor');
      supervisor.cancel();
      await secondChild.join();

      expect(log, <String>[
        'The first child is failing',
        _stillActive,
        'Cancelling the supervisor',
        'The second child is cancelled because the supervisor was cancelled',
      ]);
    }),
  );

  test(
    'supervision scope',
    () => runTest((it) async {
      final log = <String>[];
      try {
        await supervisorScope((it) async {
          it.launch((it) async {
            try {
              log.add('The child is sleeping');
              await awaitCancellation();
            } finally {
              log.add('The child is cancelled');
            }
          });
          await yieldNow();
          log.add('Throwing an exception from the scope');
          throw AssertionException();
        });
      } on AssertionException {
        log.add('Caught an assertion error');
      }

      expect(log, <String>[
        'The child is sleeping',
        'Throwing an exception from the scope',
        'The child is cancelled',
        'Caught an assertion error',
      ]);
    }),
  );

  test(
    'exceptions in supervised coroutines',
    () => runTest((it) async {
      final log = <String>[];
      final CoroutineExceptionHandler handler = _handler(log);
      await supervisorScope((it) {
        it.launch((it) {
          log.add('The child throws an exception');
          throw AssertionException();
        }, context: handler);
        log.add('The scope is completing');
      });
      log.add('The scope is completed');

      expect(log, <String>[
        'The scope is completing',
        'The child throws an exception',
        'CoroutineExceptionHandler got AssertionException',
        'The scope is completed',
      ]);
    }),
  );
}
