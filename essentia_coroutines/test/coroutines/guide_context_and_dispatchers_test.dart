/*
 * Copyright 2026 Davils
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:essentia_core/essentia_core.dart';
import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:essentia_coroutines/testing.dart';
import 'package:test/test.dart';

import 'guide_activity.dart';

/// What the request of the example prints once its own body is done.
const _requestDone =
    "request: I'm done and I don't explicitly join my children that are "
    'still active';

/// Renders [message] behind the name of the current coroutine.
///
/// Returns `[name] message`.
String _named(String message) =>
    '[${currentCoroutineContext().get(CoroutineName.key)?.name}] $message';

/// Covers the worked examples of coroutine context and dispatchers that a
/// single isolate can express, with the output they print as a golden log.
void main() {
  test(
    'dispatchers',
    () => runTest((it) async {
      final log = <String>[];
      it
        ..launch((it) => log.add('main runBlocking: I am working'))
        ..launch(
          (it) => log.add('Unconfined: I am working'),
          context: Dispatchers.unconfined,
        )
        ..launch(
          (it) => log.add('Main: I am working'),
          context: Dispatchers.main,
        );
      await yieldNow();

      expect(log, <String>[
        'Unconfined: I am working',
        'Main: I am working',
        'main runBlocking: I am working',
      ]);
    }),
  );

  test(
    'unconfined vs confined dispatcher',
    () => runTest((it) async {
      final log = <String>[];
      it
        ..launch((it) async {
          log.add('Unconfined: I am working');
          await delay(500.milliseconds);
          log.add('Unconfined: After delay');
        }, context: Dispatchers.unconfined)
        ..launch((it) async {
          log.add('main runBlocking: I am working');
          await delay(1.seconds);
          log.add('main runBlocking: After delay');
        });
      await delay(2.seconds);

      expect(log, <String>[
        'Unconfined: I am working',
        'main runBlocking: I am working',
        'Unconfined: After delay',
        'main runBlocking: After delay',
      ]);
    }),
  );

  test(
    'job in the context',
    () => runTest((it) {
      expect(
        'My job is ${currentCoroutineContext().job}',
        'My job is TestScope(active)',
      );
    }),
  );

  test(
    'children of a coroutine',
    () => runTest((it) async {
      final log = <String>[];
      final Job request = it.launch((it) {
        it
          ..launch((it) async {
            log.add('job1: I run in my own Job and execute independently!');
            await delay(1.seconds);
            log.add('job1: I am not affected by cancellation of the request');
          }, context: Job())
          ..launch((it) async {
            await delay(100.milliseconds);
            log.add('job2: I am a child of the request coroutine');
            await delay(1.seconds);
            log.add(
              'job2: I will not execute this line if my parent request is '
              'cancelled',
            );
          });
      });
      await delay(500.milliseconds);
      request.cancel();
      log.add('main: Who has survived request cancellation?');
      await delay(1.seconds);

      expect(log, <String>[
        'job1: I run in my own Job and execute independently!',
        'job2: I am a child of the request coroutine',
        'main: Who has survived request cancellation?',
        'job1: I am not affected by cancellation of the request',
      ]);
    }),
  );

  test(
    'parental responsibilities',
    () => runTest((it) async {
      final log = <String>[];
      final Job request = it.launch((it) {
        for (var i = 0; i < 3; i++) {
          it.launch((it) async {
            await delay(Duration(milliseconds: (i + 1) * 200));
            log.add('Coroutine $i is done');
          });
        }
        log.add(_requestDone);
      });
      await request.join();
      log.add('Now processing of the request is complete');

      expect(log, <String>[
        _requestDone,
        'Coroutine 0 is done',
        'Coroutine 1 is done',
        'Coroutine 2 is done',
        'Now processing of the request is complete',
      ]);
    }),
  );

  test(
    'naming coroutines for debugging',
    () => runTest((it) async {
      final log = <String>[];
      await withContext(const CoroutineName('main'), (it) async {
        log.add(_named('Started main coroutine'));
        final Deferred<int> v1 = it.async((it) async {
          await delay(500.milliseconds);
          log.add(_named('Computing v1'));
          return 6;
        }, context: const CoroutineName('v1coroutine'));
        final Deferred<int> v2 = it.async((it) async {
          await delay(1.seconds);
          log.add(_named('Computing v2'));
          return 7;
        }, context: const CoroutineName('v2coroutine'));
        log.add(_named('The answer for v1 * v2 = ${await v1 * await v2}'));
      });

      expect(log, <String>[
        '[main] Started main coroutine',
        '[v1coroutine] Computing v1',
        '[v2coroutine] Computing v2',
        '[main] The answer for v1 * v2 = 42',
      ]);
    }),
  );

  test(
    'combining context elements',
    () => runTest((it) async {
      final log = <String>[];
      await it
          .launch(
            (it) => log.add(_named("I'm working")),
            context: Dispatchers.main + const CoroutineName('test'),
          )
          .join();

      expect(log, <String>["[test] I'm working"]);
    }),
  );

  test(
    'coroutine scope',
    () => runTest((it) async {
      final log = <String>[];
      final activity = GuideActivity(log)..doSomething();
      log.add('Launched coroutines');
      await delay(500.milliseconds);
      log.add('Destroying activity!');
      activity.destroy();
      await delay(1.seconds);

      expect(log, <String>[
        'Launched coroutines',
        'Coroutine 0 is done',
        'Coroutine 1 is done',
        'Destroying activity!',
      ]);
    }),
  );
}
