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

/// Lists the elements of [context] in the order it folds them.
///
/// Returns the elements.
List<CoroutineContextElement> _elements(CoroutineContext context) =>
    context.fold<List<CoroutineContextElement>>(
      <CoroutineContextElement>[],
      (elements, element) => <CoroutineContextElement>[...elements, element],
    );

/// Covers the coroutine context: reading, folding, combining and removing
/// elements, and the context the running code sees.
void main() {
  group('the empty context', () {
    test('holds no element', () {
      const CoroutineContext empty = CoroutineContext.empty;

      expect(empty.get(Job.key), isNull);
      expect(empty.get(CoroutineName.key), isNull);
      expect(_elements(empty), isEmpty);
      expect(empty.fold<int>(7, (count, element) => count + 1), 7);
      expect(empty.toString(), '[]');
    });

    test('is the neutral element of plus', () {
      const name = CoroutineName('a');

      expect(CoroutineContext.empty + name, same(name));
      expect(name + CoroutineContext.empty, same(name));
      expect(
        CoroutineContext.empty + CoroutineContext.empty,
        same(CoroutineContext.empty),
      );
    });

    test('stays empty without a key', () {
      expect(
        CoroutineContext.empty.minusKey(Job.key),
        same(CoroutineContext.empty),
      );
    });
  });

  group('a single element', () {
    test('is a context holding only itself', () {
      const name = CoroutineName('a');

      expect(name.get(CoroutineName.key), same(name));
      expect(name.get(Job.key), isNull);
      expect(_elements(name), <CoroutineContextElement>[name]);
      expect(name.contextKey, same(CoroutineName.key));
    });

    test('removes itself only under its own key', () {
      const name = CoroutineName('a');

      expect(name.minusKey(CoroutineName.key), same(CoroutineContext.empty));
      expect(name.minusKey(Job.key), same(name));
    });

    test('is replaced by an element under the same key', () {
      const first = CoroutineName('first');
      const second = CoroutineName('second');

      expect(first + second, same(second));
    });
  });

  group('a combined context', () {
    test('answers each element under its key', () {
      final job = Job();
      const name = CoroutineName('a');
      final CoroutineContext context = name + job + Dispatchers.unconfined;

      expect(context.get(CoroutineName.key), same(name));
      expect(context.get(Job.key), same(job));
      expect(
        context.get(CoroutineDispatcher.key),
        same(Dispatchers.unconfined),
      );
      expect(context.get(Scheduler.key), isNull);
    });

    test('folds its elements in the order they were added', () {
      final job = Job();
      const name = CoroutineName('a');

      final CoroutineContext context = job + name + Dispatchers.main;

      expect(_elements(context), <Object>[job, name, Dispatchers.main]);
      expect(
        context.toString(),
        '[Job(active), CoroutineName(a), Dispatchers.main]',
      );
    });

    test('moves a replaced element to the end', () {
      final job = Job();
      final CoroutineContext context =
          const CoroutineName('old') + job + Dispatchers.main;

      final CoroutineContext replaced = context + const CoroutineName('new');

      expect(_elements(replaced), <Object>[
        job,
        Dispatchers.main,
        const CoroutineName('new'),
      ]);
      expect(_elements(context).first, const CoroutineName('old'));
    });

    test('lets the right side win when both are combined contexts', () {
      final left = Job();
      final right = Job();

      final CoroutineContext combined =
          (const CoroutineName('left') + left) +
          (right + const CoroutineName('right'));

      expect(combined.get(Job.key), same(right));
      expect(combined.get(CoroutineName.key), const CoroutineName('right'));
      expect(_elements(combined), hasLength(2));
    });

    test('removes one element and keeps the others in order', () {
      final job = Job();
      final CoroutineContext context =
          const CoroutineName('a') + job + Dispatchers.main;

      final CoroutineContext rest = context.minusKey(Job.key);

      expect(_elements(rest), <Object>[
        const CoroutineName('a'),
        Dispatchers.main,
      ]);
      expect(context.minusKey(Scheduler.key), same(context));
    });

    test('shrinks to the remaining element itself', () {
      final job = Job();
      final CoroutineContext context = const CoroutineName('a') + job;

      expect(context.minusKey(CoroutineName.key), same(job));
      expect(
        context.minusKey(CoroutineName.key).minusKey(Job.key),
        same(CoroutineContext.empty),
      );
    });

    test('keeps itself when combined with the empty context', () {
      final CoroutineContext context = const CoroutineName('a') + Job();

      expect(context + CoroutineContext.empty, same(context));
      expect(CoroutineContext.empty + context, same(context));
    });
  });

  group('a coroutine name', () {
    test('equals a name with the same text', () {
      expect(const CoroutineName('a'), const CoroutineName('a'));
      expect(CoroutineName('a'.toUpperCase()), const CoroutineName('A'));
      expect(const CoroutineName('a'), isNot(const CoroutineName('b')));
      expect(
        const CoroutineName('a').hashCode,
        const CoroutineName('a').hashCode,
      );
    });

    test('renders its text', () {
      expect(
        const CoroutineName('indexer').toString(),
        'CoroutineName(indexer)',
      );
      expect(CoroutineName.key.toString(), 'CoroutineName');
      expect(Job.key.name, 'Job');
    });
  });

  group('the current context', () {
    test('is empty outside every coroutine', () {
      expect(currentCoroutineContext(), same(CoroutineContext.empty));
    });

    test(
      'holds the coroutine itself and the context it was started with',
      () => runTest((it) async {
        final Deferred<CoroutineContext> seen = it.async((it) async {
          await delay(1.seconds);
          return currentCoroutineContext();
        }, context: const CoroutineName('worker'));

        final CoroutineContext context = await seen;

        expect(context.get(Job.key), same(seen));
        expect(context.get(CoroutineName.key), const CoroutineName('worker'));
        expect(context.get(Scheduler.key), same(it.testScheduler));
        expect(currentCoroutineContext().get(CoroutineName.key), isNull);
        expect(currentCoroutineContext().get(Job.key), same(it));
      }),
    );

    test(
      'reaches microtasks and timers started inside a coroutine',
      () => runTest((it) async {
        final seen = <String?>[];
        it.launch((it) {
          Future<void>.microtask(
            () => seen.add(
              currentCoroutineContext().get(CoroutineName.key)?.name,
            ),
          ).ignore();
          Future<void>.delayed(
            1.seconds,
            () => seen.add(
              currentCoroutineContext().get(CoroutineName.key)?.name,
            ),
          ).ignore();
        }, context: const CoroutineName('inner'));

        await delay(2.seconds);

        expect(seen, <String?>['inner', 'inner']);
      }),
    );
  });

  group('the job extensions of a context', () {
    test('answer the job, or throw without one', () {
      final job = Job();

      expect((const CoroutineName('a') + job).job, same(job));
      expect(() => const CoroutineName('a').job, throwsStateError);
    });

    test('count a context without a job as active', () {
      expect(CoroutineContext.empty.isActive, isTrue);
      expect(CoroutineContext.empty.ensureActive, returnsNormally);
      expect(CoroutineContext.empty.cancel, returnsNormally);
      expect(CoroutineContext.empty.cancelChildren, returnsNormally);
    });

    test('cancel the job of the context', () {
      final job = Job();
      final CoroutineContext context = (const CoroutineName('a') + job)
        ..cancel(const CancellationException('stop'));

      expect(context.isActive, isFalse);
      expect(
        context.ensureActive,
        throwsA(
          isA<CancellationException>().having(
            (it) => it.message,
            'message',
            'stop',
          ),
        ),
      );
    });

    test('cancel the children of the job only', () {
      final job = Job();
      final child = Job(job);

      CoroutineContextAccess(job).cancelChildren();

      expect(child.isCancelled, isTrue);
      expect(job.isActive, isTrue);
    });
  });
}
