/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';
import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:essentia_coroutines/testing.dart';
import 'package:essentia_time/essentia_time.dart';
import 'package:essentia_time/recurrence.dart';
import 'package:test/test.dart';

import 'support/topics.dart';
import 'support/user_event.dart';

/// Runs the lazy, version, principal, scheduling, text, time, time zone and
/// recurrence examples of the README, so that they stay true.
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

  test('the date, time and zone example', () {
    final TimeZone berlin = TimeZone.of('Europe/Berlin');
    final Instant start = LocalDateTime.of(2026, 3, 28, 9, 0).toInstant(berlin);

    expect(
      start.plus(1, DateTimeUnit.day, timeZone: berlin),
      Instant.parse('2026-03-29T07:00:00Z'),
    );
    expect(
      start + const Duration(days: 1),
      Instant.parse('2026-03-29T08:00:00Z'),
    );
    expect(
      berlin.offsetInfo(LocalDateTime.of(2026, 3, 29, 2, 30)),
      isA<GapOffsetInfo>(),
    );
    expect(Clock.system.todayIn(berlin).year, greaterThan(2025));
    expect(
      start.format(DateTimeFormats.isoInstantUtc),
      '2026-03-28T08:00:00.000Z',
    );
    expect(
      start.format(DateTimeFormats.dateTime, berlin),
      '2026-03-28 09:00:00.000',
    );
    expect(
      localDateTimePattern("dd.MM.yyyy 'at' HH:mm")
          .format(LocalDateTime.of(2026, 3, 28, 9, 0)),
      '28.03.2026 at 09:00',
    );
  });

  test('the recurrence example', () {
    final TimeZone berlin = TimeZone.of('Europe/Berlin');
    final standup = RecurrenceSet(
      ZonedAnchor(LocalDateTime.of(2026, 10, 5, 9, 30), berlin),
      rules: <RecurrenceRule>[RecurrenceRule.parse('FREQ=WEEKLY;BYDAY=MO,WE')],
    );

    expect(
      standup.occurrencesBetween(
        LocalDateTime.of(2026, 10, 1, 0, 0),
        LocalDateTime.of(2026, 11, 1, 0, 0),
      ),
      hasLength(8),
    );
  });
}
