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

import 'dart:async';

import 'package:essentia_core/essentia_core.dart';
import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:test/test.dart';

/// The name of the coroutine context the current code sees.
///
/// Returns the name, or `null` when the context carries none.
String? _currentName() =>
    currentCoroutineContext().get(CoroutineName.key)?.name;

/// Covers `runWithContext`: a context laid over the current one for a body,
/// synchronous or asynchronous, nested and inherited by coroutines.
void main() {
  test('returns the value of a synchronous body that sees the context', () {
    final String? seen = runWithContext(
      const CoroutineName('sync'),
      _currentName,
    );

    expect(seen, 'sync');
    expect(_currentName(), isNull);
  });

  test('returns the future of an asynchronous body unchanged', () async {
    final completer = Completer<int>();

    final Future<int> result = runWithContext(
      const CoroutineName('async'),
      () => completer.future,
    );
    completer.complete(42);

    expect(result, same(completer.future));
    expect(await result, 42);
  });

  test('carries the context across awaits, timers and microtasks', () async {
    final List<String?> seen = await runWithContext(
      const CoroutineName('carried'),
      () async {
        final String? before = _currentName();
        await Future<void>.delayed(Duration.zero);
        final String? afterAwait = _currentName();
        final timer = Completer<String?>();
        Timer(
          const Duration(milliseconds: 1),
          () => timer.complete(_currentName()),
        );
        final microtask = Completer<String?>();
        scheduleMicrotask(() => microtask.complete(_currentName()));
        return <String?>[
          before,
          afterAwait,
          await timer.future,
          await microtask.future,
          await Stream<int>.fromIterable(<int>[1])
              .map((_) => _currentName())
              .single,
        ];
      },
    );

    expect(seen, List<String?>.filled(5, 'carried'));
    expect(_currentName(), isNull);
  });

  test('lets an inner context win for its own body only', () async {
    final seen = <String?>[];

    await runWithContext(const CoroutineName('outer'), () async {
      seen.add(_currentName());
      await runWithContext(const CoroutineName('inner'), () async {
        await Future<void>.delayed(Duration.zero);
        seen.add(_currentName());
      });
      seen.add(_currentName());
    });

    expect(seen, <String?>['outer', 'inner', 'outer']);
  });

  test('keeps the elements of the outer context under other keys', () {
    final Principal alice = principal('alice');

    final (String? name, String? id) = runWithContext(
      const CoroutineName('combined'),
      () => runWithContext(
        PrincipalElement(alice),
        () => (_currentName(), currentPrincipal()?.id),
      ),
    );

    expect(name, 'combined');
    expect(id, 'alice');
  });

  test('hands the context to the coroutines launched inside', () async {
    final seen = <String?>[];

    await runWithContext(
      const CoroutineName('parent'),
      () => coroutineScope((it) async {
        it.launch((it) async {
          await delay(Duration.zero);
          seen.add(_currentName());
        });
        await withContext(Dispatchers.unconfined, (it) async {
          await delay(Duration.zero);
          seen.add(_currentName());
        });
      }),
    );

    expect(seen, <String?>['parent', 'parent']);
  });

  test('leaves a scope created elsewhere with its own context', () async {
    final scope = CoroutineScope(Job() + const CoroutineName('scope'));
    addTearDown(scope.cancel);

    final String? seen = await runWithContext(
      const CoroutineName('caller'),
      () => scope.async((it) async {
        await delay(Duration.zero);
        return _currentName();
      }),
    );

    expect(seen, 'scope');
  });

  test('hands the context to the children of a coroutine', () async {
    final String? seen = await runWithContext(
      const CoroutineName('ancestor'),
      () => coroutineScope(
        (it) => it.async((it) async {
          await delay(Duration.zero);
          return _currentName();
        }),
      ),
    );

    expect(seen, 'ancestor');
  });

  test('is what runAsPrincipal is built on', () {
    final Principal bob = principal('bob');

    final PrincipalElement? element = runAsPrincipal(
      bob,
      () => currentCoroutineContext().get(PrincipalElement.key),
    );

    expect(element?.principal, same(bob));
  });
}
