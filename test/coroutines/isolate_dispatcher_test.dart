/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

@TestOn('vm')
library;

import 'dart:async';
import 'dart:isolate';

import 'package:essentia/essentia.dart';
import 'package:essentia/src/coroutines/isolate_worker_io.dart';
import 'package:test/test.dart';

import 'local_element.dart';
import 'port_element.dart';
import 'tenant_element.dart';
import 'unsendable.dart';

/// Covers `Dispatchers.isolate`: bodies on worker isolates, what crosses
/// to them, failures, cancellation and limited parallelism.
void main() {
  test('runs a body on a worker isolate and returns its result', () async {
    final String here = Isolate.current.debugName ?? '';

    final (String there, int sum) = await withContext(
      Dispatchers.isolate,
      (it) => (Isolate.current.debugName ?? '', _sumTo(1000)),
    );

    expect(sum, 500500);
    expect(there, isNot(here));
    expect(there, 'Dispatchers.isolate');
  });

  test('carries the name and the principal to the isolate', () async {
    final Principal alice = principal('alice');

    final (String? name, String? id) = await runAsPrincipal(
      alice,
      () => withContext(
        Dispatchers.isolate + const CoroutineName('hashing'),
        (it) => (
          currentCoroutineContext().get(CoroutineName.key)?.name,
          currentPrincipal()?.id,
        ),
      ),
    );

    expect(name, 'hashing');
    expect(id, 'alice');
  });

  test('carries every element marked isolate transferable', () async {
    final String? tenant = await withContext(
      Dispatchers.isolate + const TenantElement('acme'),
      (it) => currentCoroutineContext().get(TenantElement.key)?.tenant,
    );

    expect(tenant, 'acme');
  });

  test('leaves an element behind that is not marked', () async {
    final (bool local, String? tenant) = await withContext(
      Dispatchers.isolate + const LocalElement() + const TenantElement('acme'),
      (it) => (
        currentCoroutineContext().get(LocalElement.key) != null,
        currentCoroutineContext().get(TenantElement.key)?.tenant,
      ),
    );

    expect(local, isFalse);
    expect(tenant, 'acme');
  });

  test('drops only the elements that cannot be sent', () async {
    final port = ReceivePort();
    addTearDown(port.close);
    final Principal alice = principal('alice');

    final (
      String? name,
      String? id,
      String? tenant,
      bool hasPort,
    ) = await runAsPrincipal(
      alice,
      () => withContext(
        Dispatchers.isolate +
            const CoroutineName('mixed') +
            PortElement(port) +
            const TenantElement('acme'),
        (it) => (
          currentCoroutineContext().get(CoroutineName.key)?.name,
          currentPrincipal()?.id,
          currentCoroutineContext().get(TenantElement.key)?.tenant,
          currentCoroutineContext().get(PortElement.key) != null,
        ),
      ),
    );

    expect(name, 'mixed');
    expect(id, 'alice');
    expect(tenant, 'acme');
    expect(hasPort, isFalse);
  });

  test('still refuses a body that cannot be sent with its elements', () async {
    final port = ReceivePort();
    addTearDown(port.close);

    await expectLater(
      withContext(
        Dispatchers.isolate + PortElement(port),
        (it) => port.sendPort.hashCode,
      ),
      throwsA(isA<IsolateBodyNotSendableError>()),
    );
  });

  test('runs async bodies started with launch and async', () async {
    final scope = CoroutineScope(Job() + Dispatchers.isolate);
    addTearDown(scope.cancel);

    final Deferred<int> sum = scope.async((it) async {
      await delay(Duration.zero);
      return _sumTo(10);
    });

    expect(await sum, 55);
  });

  test('throws the failure of the body with its message', () async {
    await expectLater(
      withContext(
        Dispatchers.isolate,
        (it) => throw StateError('broken on the worker'),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'broken on the worker',
        ),
      ),
    );
  });

  test('refuses a body that captures what cannot be sent', () async {
    final port = ReceivePort();
    addTearDown(port.close);

    await expectLater(
      withContext(Dispatchers.isolate, (it) => port.sendPort.hashCode),
      throwsA(
        isA<IsolateBodyNotSendableError>().having(
          (error) => error.inResult,
          'inResult',
          isFalse,
        ),
      ),
    );
  });

  test('refuses a result that cannot be sent back', () async {
    await expectLater(
      withContext(Dispatchers.isolate, (it) => ReceivePort()),
      throwsA(
        isA<IsolateBodyNotSendableError>().having(
          (error) => error.inResult,
          'inResult',
          isTrue,
        ),
      ),
    );
  });

  test('cancels the body on the isolate with its caller', () async {
    final scope = CoroutineScope(Job());
    final Job job = scope.launch(
      (it) => withContext(Dispatchers.isolate, (it) async {
        while (true) {
          await delay(const Duration(milliseconds: 1));
        }
      }),
    );
    await Future<void>.delayed(Duration.zero);

    await job.cancelAndJoin();

    expect(job.isCancelled, isTrue);
  });

  test('kills a worker that ignores the cancellation of its job', () async {
    final worker = IsolateWorkerIo(killGrace: const Duration(milliseconds: 20));
    addTearDown(worker.shutDown);
    final job = CompletableJob();
    final Future<int> result = worker.run(job, (it) => Completer<int>().future);
    await pumpEventQueue();

    job.cancel();

    await expectLater(result, throwsA(isA<CancellationException>()));
    expect(worker.isAlive, isFalse);
  });

  test('fails the body of an isolate that exits', () async {
    final worker = IsolateWorkerIo();
    addTearDown(worker.shutDown);

    await expectLater(
      worker.run<int>(CoroutineContext.empty, (it) => Isolate.exit()),
      throwsA(isA<RemoteError>()),
    );
    expect(worker.isAlive, isFalse);
  });

  test('fails the body of an isolate with an uncaught error', () async {
    final worker = IsolateWorkerIo();
    addTearDown(worker.shutDown);

    await expectLater(
      worker.run<int>(CoroutineContext.empty, (it) {
        Timer.run(() => throw StateError('escaped'));
        return Completer<int>().future;
      }),
      throwsA(
        isA<RemoteError>().having(
          (error) => error.toString(),
          'text',
          contains('escaped'),
        ),
      ),
    );
    expect(worker.isAlive, isFalse);
  });

  test('keeps a worker for the next body', () async {
    final worker = IsolateWorkerIo();
    addTearDown(worker.shutDown);

    final int first = await worker.run(
      CoroutineContext.empty,
      (it) => Isolate.current.hashCode,
    );
    final int second = await worker.run(
      CoroutineContext.empty,
      (it) => Isolate.current.hashCode,
    );

    expect(worker.isAlive, isTrue);
    expect(second, first);
  });

  test('turns an error that cannot be sent back into a remote error', () async {
    await expectLater(
      withContext(Dispatchers.isolate, (it) => throw Unsendable(ReceivePort())),
      throwsA(
        isA<RemoteError>().having(
          (error) => error.toString(),
          'text',
          contains('unsendable'),
        ),
      ),
    );
  });

  test(
    'never runs the body of a coroutine cancelled before it started',
    () async {
      final scope = CoroutineScope(Job()..cancel());
      var ran = false;

      final Deferred<int> result = scope.async((it) {
        ran = true;
        return 1;
      }, context: Dispatchers.isolate);

      await expectLater(result, throwsA(isA<CancellationException>()));
      expect(ran, isFalse);
    },
  );

  test('starts a plain block on the event loop', () async {
    final log = <String>[];
    final dispatchers = <CoroutineDispatcher>[
      Dispatchers.isolate,
      Dispatchers.isolate.limitedParallelism(2),
    ];

    for (final dispatcher in dispatchers) {
      dispatcher.dispatch(
        CoroutineContext.empty,
        Zone.current,
        () => log.add('$dispatcher'),
      );
    }
    await pumpEventQueue();

    expect(log, <String>[
      'Dispatchers.isolate',
      'Dispatchers.isolate.limitedParallelism(2)',
    ]);
    expect(
      Dispatchers.isolate
          .limitedParallelism(2)
          .limitedParallelism(1)
          .toString(),
      'Dispatchers.isolate.limitedParallelism(1)',
    );
    expect(
      () => Dispatchers.isolate.limitedParallelism(2).limitedParallelism(0),
      throwsRangeError,
    );
  });

  test('renders what could not be sent without quoting it', () {
    expect(
      IsolateBodyNotSendableError.body(StateError('x')).toString(),
      startsWith('IsolateBodyNotSendableError: A body run on'),
    );
    expect(
      IsolateBodyNotSendableError.result().toString(),
      startsWith('IsolateBodyNotSendableError: The result of a body'),
    );
  });

  test('runs no more bodies at once than its limit allows', () async {
    final CoroutineDispatcher single = Dispatchers.isolate.limitedParallelism(
      1,
    );
    final log = <int>[];

    await Future.wait(<Future<void>>[
      for (var index = 0; index < 3; index++)
        withContext(single, (it) => index).then(log.add),
    ]);

    expect(log, <int>[0, 1, 2]);
    expect(single.toString(), 'Dispatchers.isolate.limitedParallelism(1)');
    expect(() => Dispatchers.isolate.limitedParallelism(0), throwsRangeError);
  });
}

/// Adds the numbers from one to [limit].
///
/// Returns the sum.
int _sumTo(int limit) {
  var sum = 0;
  for (var number = 1; number <= limit; number++) {
    sum += number;
  }
  return sum;
}
