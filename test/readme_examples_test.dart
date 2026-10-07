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

import 'support/topics.dart';
import 'support/user_event.dart';

/// Runs the lazy, version, principal, scheduling, text and time examples of
/// the README, so that they stay true.
void main() {
  test('the lazy example', () {
    final Lazy<RegExp> word = lazy(() => RegExp(r'^[a-z]+$'));
    bool isWord(String text) => word.value.hasMatch(text);

    expect(word.isInitialized, isFalse);
    expect(isWord('essentia'), isTrue);
    expect(isWord('Essentia 1'), isFalse);
    expect(word.isInitialized, isTrue);
    expect(lazyOf(3).value, 3);
  });

  test('the semantic version example', () {
    final version = SemanticVersion.parse('1.4.0-rc.1');
    final range = SemanticVersionRange.parse('^1.2 || >=2.0.0 <2.1.0');

    expect(range.contains(version), isTrue);
    expect(range.contains(version, PreReleasePolicy.sameCoreOnly), isFalse);
    expect(version.nextMinor(), SemanticVersion.parse('1.4.0'));
    expect('1.2.3'.toSemanticVersionOrNull(), SemanticVersion.parse('1.2.3'));
  });

  test('the principal example', () async {
    final Principal alice = principal(
      'alice',
      (it) => it.roles(<String>['admin']),
    );
    final EventBus bus = eventBus((it) => it.topic(users));
    final seen = <String?>[];
    bus.topic(users).subscribe((_) => seen.add(currentPrincipal()?.id));

    await runAsPrincipal(alice, () async {
      expect(requirePrincipal().hasRole('admin'), isTrue);
      await bus.topic(users).publish(const Registered('u-42'));
    });
    await Future<void>.delayed(Duration.zero);
    await bus.drain();

    expect(seen, <String?>['alice']);
  });

  test(
    'the coroutines example',
    () => runTest((it) async {
      var refreshes = 0;
      Future<void> refresh() async => refreshes++;
      Future<String> loadUser(String id) async => 'user $id';
      Future<List<String>> loadOrders(String id) async => <String>['order'];
      Future<String> build() async {
        await delay(10.seconds);
        return 'report';
      }

      const id = '42';
      final scope = CoroutineScope(SupervisorJob());
      final Job polling = scope.launch((it) async {
        while (true) {
          await delay(30.seconds);
          await refresh();
        }
      });

      final (String user, List<String> orders) = await coroutineScope((
        it,
      ) async {
        final Deferred<String> user = it.async((it) => loadUser(id));
        final Deferred<List<String>> orders = it.async((it) => loadOrders(id));
        return (await user, await orders);
      });
      final String? report = await withTimeoutOrNull(
        5.seconds,
        (it) => build(),
      );
      await delay(90.seconds);
      await polling.cancelAndJoin();

      expect(user, 'user 42');
      expect(orders, <String>['order']);
      expect(report, isNull);
      expect(refreshes, 3);
      expect(polling.isCancelled, isTrue);
    }),
  );

  test(
    'the runTest example',
    () => runTest((it) async {
      var polls = 0;
      Future<void> poll() async {
        while (true) {
          await delay(30.seconds);
          polls++;
        }
      }

      it.backgroundScope.launch((it) => poll());
      await delay(100.seconds);
      expect(polls, 3);
    }),
  );

  test(
    'the channels, select and hot flows example',
    () => runTest((it) async {
      final printed = <Object?>[];
      void print(Object? value) => printed.add(value);
      final scope = CoroutineScope(SupervisorJob());
      final fast = Channel<int>(capacity: 1);
      final slow = Channel<int>();

      final ReceiveChannel<int> squares = scope.produce((it) async {
        for (var x = 1; x <= 5; x++) {
          await it.send(x * x);
        }
      });
      await squares.consumeEach(print);

      await fast.send(7);
      final String winner = await select((it) {
        it
          ..onReceive(fast, (value) => 'fast: $value')
          ..onReceive(slow, (value) => 'slow: $value')
          ..onTimeout(1.seconds, () => 'none in time');
      });

      final MutableStateFlow<int> counter = MutableStateFlow(0)
        ..update((it) => it + 1);
      final Job watching = counter.launchIn(scope);

      expect(printed, <int>[1, 4, 9, 16, 25]);
      expect(winner, 'fast: 7');
      expect(counter.value, 1);
      await watching.cancelAndJoin();
      scope.cancel();
    }),
  );

  test('the text and time examples', () {
    expect('HTTPServer'.toSnakeCase(), 'http_server');
    expect('lease_duration'.toCamelCase(), 'leaseDuration');
    expect('--prot'.closestIn(<String>['--port', '--host']), '--port');
    expect('PT1H30M'.toIsoDuration(), const Duration(hours: 1, minutes: 30));
    expect(Platform.parse('linux-x86_64').isLinux, isTrue);
  });
}
