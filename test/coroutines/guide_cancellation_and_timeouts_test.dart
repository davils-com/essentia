/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';
import 'package:essentia/testing.dart';
import 'package:test/test.dart';

import 'guide_counter.dart';
import 'guide_resource.dart';

/// Covers the examples of the kotlinx.coroutines guide "Cancellation and
/// timeouts", ported line by line, with the output they print as a golden
/// log.
void main() {
  test(
    'cancelling coroutine execution',
    () => runTest((it) async {
      final log = <String>[];
      final Job job = it.launch((it) async {
        for (var i = 0; i < 1000; i++) {
          log.add("job: I'm sleeping $i ...");
          await delay(500.milliseconds);
        }
      });
      await delay(1300.milliseconds);
      log.add("main: I'm tired of waiting!");
      job.cancel();
      await job.join();
      log.add('main: Now I can quit.');

      expect(log, <String>[
        "job: I'm sleeping 0 ...",
        "job: I'm sleeping 1 ...",
        "job: I'm sleeping 2 ...",
        "main: I'm tired of waiting!",
        'main: Now I can quit.',
      ]);
    }),
  );

  test(
    'making computation code cancellable',
    () => runTest((it) async {
      final log = <String>[];
      final Job job = it.launch((it) async {
        var i = 0;
        while (it.isActive) {
          log.add("job: I'm sleeping ${i++} ...");
          await Future<void>.delayed(500.milliseconds);
        }
      });
      await delay(1300.milliseconds);
      log.add("main: I'm tired of waiting!");
      await job.cancelAndJoin();
      log.add('main: Now I can quit.');

      expect(log, <String>[
        "job: I'm sleeping 0 ...",
        "job: I'm sleeping 1 ...",
        "job: I'm sleeping 2 ...",
        "main: I'm tired of waiting!",
        'main: Now I can quit.',
      ]);
    }),
  );

  test(
    'closing resources with finally',
    () => runTest((it) async {
      final log = <String>[];
      final Job job = it.launch((it) async {
        try {
          for (var i = 0; i < 1000; i++) {
            log.add("job: I'm sleeping $i ...");
            await delay(500.milliseconds);
          }
        } finally {
          log.add("job: I'm running finally");
        }
      });
      await delay(1300.milliseconds);
      log.add("main: I'm tired of waiting!");
      await job.cancelAndJoin();
      log.add('main: Now I can quit.');

      expect(log, <String>[
        "job: I'm sleeping 0 ...",
        "job: I'm sleeping 1 ...",
        "job: I'm sleeping 2 ...",
        "main: I'm tired of waiting!",
        "job: I'm running finally",
        'main: Now I can quit.',
      ]);
    }),
  );

  test(
    'run non-cancellable block',
    () => runTest((it) async {
      final log = <String>[];
      final Job job = it.launch((it) async {
        try {
          for (var i = 0; i < 1000; i++) {
            log.add("job: I'm sleeping $i ...");
            await delay(500.milliseconds);
          }
        } finally {
          await withContext(NonCancellable.instance, (it) async {
            log.add("job: I'm running finally");
            await delay(1.seconds);
            log.add(
              "job: And I've just delayed for 1 sec because I'm "
              'non-cancellable',
            );
          });
        }
      });
      await delay(1300.milliseconds);
      log.add("main: I'm tired of waiting!");
      await job.cancelAndJoin();
      log.add('main: Now I can quit.');

      expect(log, <String>[
        "job: I'm sleeping 0 ...",
        "job: I'm sleeping 1 ...",
        "job: I'm sleeping 2 ...",
        "main: I'm tired of waiting!",
        "job: I'm running finally",
        "job: And I've just delayed for 1 sec because I'm non-cancellable",
        'main: Now I can quit.',
      ]);
    }),
  );

  test(
    'timeout',
    () => runTest((it) async {
      final log = <String>[];
      try {
        await withTimeout(1300.milliseconds, (it) async {
          for (var i = 0; i < 1000; i++) {
            log.add("I'm sleeping $i ...");
            await delay(500.milliseconds);
          }
        });
      } on TimeoutCancellationException catch (cause) {
        log.add('$cause');
      }

      expect(log, <String>[
        "I'm sleeping 0 ...",
        "I'm sleeping 1 ...",
        "I'm sleeping 2 ...",
        'TimeoutCancellationException: Timed out waiting for 1300 ms',
      ]);
    }),
  );

  test(
    'timeout or null',
    () => runTest((it) async {
      final log = <String>[];
      final String? result = await withTimeoutOrNull(1300.milliseconds, (
        it,
      ) async {
        for (var i = 0; i < 1000; i++) {
          log.add("I'm sleeping $i ...");
          await delay(500.milliseconds);
        }
        return 'Done';
      });
      log.add('Result is $result');

      expect(log, <String>[
        "I'm sleeping 0 ...",
        "I'm sleeping 1 ...",
        "I'm sleeping 2 ...",
        'Result is null',
      ]);
    }),
  );

  test(
    'asynchronous timeout and resources',
    () => runTest((it) async {
      final counter = GuideCounter();
      await coroutineScope((it) {
        for (var index = 0; index < 1000; index++) {
          it.launch((it) async {
            GuideResource? resource;
            try {
              await withTimeout(60.milliseconds, (it) async {
                await delay(50.milliseconds);
                resource = GuideResource(counter);
              });
            } finally {
              resource?.close();
            }
          });
        }
      });

      expect(counter.open, 0);
    }),
  );
}
