/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';
import 'package:test/test.dart';

import '../support/audit_event.dart';
import '../support/recording_listener.dart';
import '../support/topics.dart';
import '../support/user_event.dart';
import 'broken_exporter_listener.dart';

/// Creates an interceptor that writes to [log], under [label], when the
/// handling enters it and when it leaves it again.
///
/// Returns the interceptor.
EventInterceptor _trace(List<String> log, String label) =>
    (envelope, consumer, proceed) async {
      log.add('$label in');
      await proceed();
      log.add('$label out');
    };

/// Reads the message of [error], or its rendering when it carries none.
///
/// Returns the message.
String _messageOf(Object error) {
  if (error is StateError) {
    return error.message;
  }
  return '$error';
}

/// Checks what interceptors, listeners and metrics are told about a topic.
void main() {
  group('interceptors', () {
    test('wrap the consumer, outermost first in declaration order', () async {
      final log = <String>[];
      final EventBus bus = eventBus((it) {
        it
          ..intercept(_trace(log, 'bus'))
          ..topic(users, (it) => it.intercept(_trace(log, 'topic')));
      });
      final EventSubscription subscription = bus
          .topic(users)
          .subscribe((_) => log.add('consumer'));
      await subscription.awaitReady();

      await bus.topic(users).publish(const Registered('u-1'));
      await bus.drain();
      await subscription.join();

      expect(log, <String>[
        'bus in',
        'topic in',
        'consumer',
        'topic out',
        'bus out',
      ]);
    });

    test('are told which consumer is about to handle what', () async {
      final seen = <(String, String)>[];
      final EventBus bus = eventBus((it) {
        it
          ..intercept((envelope, consumer, proceed) async {
            seen.add((consumer, envelope.topic));
            await proceed();
          })
          ..topic(users);
      });
      final EventSubscription subscription = bus
          .topic(users)
          .subscribe((_) {}, name: 'watcher');
      await subscription.awaitReady();
      bus.topic(users).group('worker', (_) {});

      await bus.topic(users).publish(const Registered('u-1'));
      await bus.drain();
      await subscription.join();

      expect(seen.map((it) => it.$1).toSet(), <String>{'watcher', 'worker'});
      expect(seen.map((it) => it.$2).toSet(), <String>{'users'});
    });

    test(
      'one that does not proceed keeps the envelope from the consumer',
      () async {
        final listener = RecordingListener();
        final handled = <String>[];
        final EventBus bus = eventBus((it) {
          it
            ..listener = listener
            ..intercept((envelope, _, proceed) async {
              final Event payload = envelope.payload;
              if (payload is UserEvent && payload.userId != 'blocked') {
                await proceed();
              }
            })
            ..topic(users);
        });
        final EventSubscription subscription = bus
            .topic(users)
            .subscribe((it) => handled.add(it.payload.userId));
        await subscription.awaitReady();

        await bus.topic(users).publish(const Registered('allowed'));
        await bus.topic(users).publish(const Registered('blocked'));
        await bus.drain();
        await subscription.join();

        expect(handled, <String>['allowed']);
        expect(listener.delivered, hasLength(1));
      },
    );

    test('one that throws is reported as the consumer failing', () async {
      final listener = RecordingListener();
      final failures = <String>[];
      final EventBus bus = eventBus((it) {
        it
          ..listener = listener
          ..onError = (error, _) {
            failures.add(_messageOf(error));
          }
          ..intercept((_, _, _) => throw StateError('interceptor said no'))
          ..topic(users);
      });
      final EventSubscription subscription = bus.topic(users).subscribe((_) {});
      await subscription.awaitReady();

      await bus.topic(users).publish(const Registered('u-1'));
      await bus.topic(users).publish(const Registered('u-2'));
      await bus.drain();
      await subscription.join();

      expect(failures, <String>['interceptor said no', 'interceptor said no']);
      expect(listener.failed, hasLength(2));
      expect(listener.delivered, isEmpty);
    });

    test('a topic declared before a bus-wide one does not get it', () async {
      final log = <String>[];
      final early = TopicKey<UserEvent>('early');
      final late = TopicKey<AuditEvent>('late');
      final EventBus bus = eventBus((it) {
        it
          ..topic(early)
          ..intercept(_trace(log, 'bus'))
          ..topic(late);
      });
      final EventSubscription first = bus.topic(early).subscribe((_) {});
      final EventSubscription second = bus.topic(late).subscribe((_) {});
      await first.awaitReady();
      await second.awaitReady();

      await bus.topic(early).publish(const Registered('u-1'));
      await bus.drain();
      await first.join();
      await second.join();

      expect(log, isEmpty);
    });
  });

  group('the listener', () {
    test(
      'is told about a publication, each delivery of it, and nothing else',
      () async {
        final listener = RecordingListener();
        final EventBus bus = eventBus((it) {
          it
            ..listener = listener
            ..topic(users);
        });
        final EventSubscription one = bus
            .topic(users)
            .subscribe((_) {}, name: 'one');
        final EventSubscription two = bus
            .topic(users)
            .subscribe((_) {}, name: 'two');
        await one.awaitReady();
        await two.awaitReady();

        await bus.topic(users).publish(const Registered('u-1'));
        await bus.drain();
        await one.join();
        await two.join();

        expect(listener.published, hasLength(1));
        expect(listener.delivered.map((it) => it.$2).toSet(), <String>{
          'one',
          'two',
        });
        expect(listener.failed, isEmpty);
        expect(listener.dropped, isEmpty);
      },
    );

    test('one that throws does not take the topic down and is reported as a '
        'failure', () async {
      final failures = <String>[];
      final handled = <String>[];
      final EventBus bus = eventBus((it) {
        it
          ..listener = const BrokenExporterListener()
          ..onError = (error, _) {
            failures.add(_messageOf(error));
          }
          ..topic(users);
      });
      final EventSubscription subscription = bus
          .topic(users)
          .subscribe((it) => handled.add(it.payload.userId));
      await subscription.awaitReady();

      await bus.topic(users).publish(const Registered('u-1'));
      await bus.topic(users).publish(const Registered('u-2'));
      await bus.drain();
      await subscription.join();

      expect(handled, <String>['u-1', 'u-2']);
      expect(failures, <String>[
        BrokenExporterListener.message,
        BrokenExporterListener.message,
      ]);
      expect(bus.topic(users).state, BusState.closed);
    });
  });

  group('metrics', () {
    test('count what happened without a listener being registered', () async {
      final EventBus bus = eventBus((it) => it.topic(users));
      final EventSubscription one = bus
          .topic(users)
          .subscribe((_) {}, name: 'one');
      final EventSubscription two = bus
          .topic(users)
          .subscribe((_) => throw StateError('no'), name: 'two');
      await one.awaitReady();
      await two.awaitReady();

      for (var ordinal = 0; ordinal < 5; ordinal++) {
        await bus.topic(users).publish(Registered('u-$ordinal'));
      }
      await bus.drain();
      await one.join();
      await two.join();

      final TopicMetrics metrics = bus.topic(users).metrics;
      expect(metrics.published, 5);
      expect(metrics.delivered, 5);
      expect(metrics.failed, 5);
      expect(metrics.dropped, 0);
      expect(metrics.queueDepth, 0);
    });

    test('count what was discarded', () {
      final EventBus bus = eventBus((it) {
        it.topic(users, (it) {
          it
            ..bufferCapacity = 2
            ..overflow = OverflowPolicy.dropLatest;
        });
      });

      for (var ordinal = 0; ordinal < 10; ordinal++) {
        bus.topic(users).tryPublish(Registered('u-$ordinal'));
      }

      expect(bus.topic(users).metrics.dropped, greaterThan(0));
      bus.dispose();
    });

    test('report what is attached and what is waiting', () async {
      final EventBus bus = eventBus(
        (it) => it.topic(users, (it) => it.bufferCapacity = 16),
      );
      final EventSubscription subscription = bus.topic(users).subscribe((_) {});
      await subscription.awaitReady();
      bus.topic(users).group('worker', (_) {});

      for (var ordinal = 0; ordinal < 4; ordinal++) {
        bus.topic(users).tryPublish(Registered('u-$ordinal'));
      }

      final TopicMetrics metrics = bus.topic(users).metrics;
      expect(metrics.subscribers, 1);
      expect(metrics.groups, 1);
      expect(metrics.queueDepth, greaterThan(0));

      await bus.drain();
      await subscription.join();
      expect(bus.topic(users).metrics.queueDepth, 0);
    });

    test('survive a shutdown and still say what was lost', () {
      final EventBus bus = eventBus(
        (it) => it.topic(users, (it) => it.bufferCapacity = 16),
      );

      for (var ordinal = 0; ordinal < 10; ordinal++) {
        bus.topic(users).tryPublish(Registered('u-$ordinal'));
      }
      bus.dispose();

      final TopicMetrics metrics = bus.topic(users).metrics;
      expect(metrics.published, 10);
      expect(metrics.dropped, 10 - bus.topic(users).partitionCount);
      expect(metrics.toString(), contains('dropped=9'));
    });

    test('a drop reported to the listener is the same one the counter saw', () {
      final listener = RecordingListener();
      final EventBus bus = eventBus((it) {
        it
          ..listener = listener
          ..topic(users, (it) => it.bufferCapacity = 8);
      });

      for (var ordinal = 0; ordinal < 3; ordinal++) {
        bus.topic(users).tryPublish(Registered('u-$ordinal'));
      }
      bus.dispose();

      expect(listener.dropped, hasLength(bus.topic(users).metrics.dropped));
      expect(listener.dropReasons.toSet(), <DropReason>{DropReason.disposed});
    });
  });
}
