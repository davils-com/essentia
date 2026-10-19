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
import 'package:test/test.dart';

import '../support/audit_event.dart';
import '../support/recording_listener.dart';
import '../support/topics.dart';
import '../support/user_event.dart';

/// Checks how a bus starts, drains and stops.
void main() {
  test('a bus is running until it is stopped', () {
    final EventBus bus = eventBus((it) => it.topic(users));

    expect(bus.state, BusState.running);
    expect(bus.topic(users).state, BusState.running);

    bus.dispose();

    expect(bus.state, BusState.closed);
    expect(bus.topic(users).state, BusState.closed);
  });

  test('draining hands over everything that is still buffered', () async {
    final listener = RecordingListener();
    final EventBus bus = eventBus((it) {
      it
        ..listener = listener
        ..topic(users, (it) => it.bufferCapacity = 64);
    });
    final received = <String>[];
    final EventSubscription subscription = bus
        .topic(users)
        .subscribe((it) => received.add(it.payload.userId));
    await subscription.awaitReady();

    final published = List<String>.generate(20, (index) => 'u-$index');
    for (final id in published) {
      await bus.topic(users).publish(Registered(id));
    }
    await bus.drain();
    await subscription.join();

    expect(received, published);
    expect(listener.dropped, isEmpty);
    expect(bus.state, BusState.closed);
  });

  test('draining refuses publications from the moment it is called', () async {
    final listener = RecordingListener();
    final EventBus bus = eventBus((it) {
      it
        ..listener = listener
        ..topic(users);
    });
    final EventTopic<UserEvent> topic = bus.topic(users);
    expect(topic.tryPublish(const Registered('u-1')), isNotNull);

    final Future<void> draining = bus.drain();

    expect(bus.state, BusState.draining);
    expect(topic.state, BusState.draining);
    expect(topic.tryPublish(const Registered('u-2')), isNull);
    expect(await topic.publish(const Registered('u-3')), isNull);
    await draining;

    expect(listener.dropReasons, <DropReason>[
      DropReason.closed,
      DropReason.closed,
    ]);
    expect(bus.state, BusState.closed);
  });

  test('stopping abruptly reports what it was still holding rather than losing '
      'it quietly', () {
    final listener = RecordingListener();
    final EventBus bus = eventBus((it) {
      it
        ..listener = listener
        ..topic(users, (it) => it.bufferCapacity = 64);
    });

    for (var ordinal = 0; ordinal < 20; ordinal++) {
      bus.topic(users).tryPublish(Registered('u-$ordinal'));
    }
    bus.dispose();

    expect(listener.dropped, hasLength(20 - bus.topic(users).partitionCount));
    expect(listener.dropReasons.toSet(), <DropReason>{DropReason.disposed});
    expect(listener.delivered, isEmpty);
  });

  test('publishing to a stopped topic is refused and reported', () async {
    final listener = RecordingListener();
    final EventBus bus = eventBus((it) {
      it
        ..listener = listener
        ..topic(users);
    })..dispose();

    expect(await bus.topic(users).publish(const Registered('u-1')), isNull);
    expect(bus.topic(users).tryPublish(const Registered('u-2')), isNull);

    expect(listener.dropReasons, <DropReason>[
      DropReason.closed,
      DropReason.closed,
    ]);
    expect(listener.published, isEmpty);
  });

  group('stopping twice is not an error', () {
    test('abruptly, then abruptly', () {
      final listener = RecordingListener();
      final EventBus bus = eventBus((it) {
        it
          ..listener = listener
          ..topic(users);
      });
      for (var ordinal = 0; ordinal < 5; ordinal++) {
        bus.topic(users).tryPublish(Registered('u-$ordinal'));
      }

      bus.dispose();
      final int afterFirst = listener.dropped.length;
      bus.dispose();

      expect(afterFirst, 4);
      expect(listener.dropped, hasLength(afterFirst));
    });

    test('draining, then draining', () async {
      final EventBus bus = eventBus((it) => it.topic(users));

      await bus.drain();
      await bus.drain();

      expect(bus.state, BusState.closed);
    });

    test('draining, then abruptly', () async {
      final EventBus bus = eventBus((it) => it.topic(users));

      await bus.drain();
      bus.dispose();

      expect(bus.state, BusState.closed);
    });

    test('draining twice at once, both waiting for the first', () async {
      final EventBus bus = eventBus((it) => it.topic(users));

      final Future<void> first = bus.drain();
      final Future<void> second = bus.drain();
      await Future.wait(<Future<void>>[first, second]);

      expect(bus.state, BusState.closed);
    });
  });

  test('stopping the bus cancels the subscriptions it hosts', () async {
    final EventBus bus = eventBus((it) => it.topic(users));
    final EventSubscription subscription = bus.topic(users).subscribe((_) {});
    await subscription.awaitReady();

    bus.dispose();

    expect(subscription.isActive, isFalse);
    await subscription.join();
  });

  test('subscribing to a stopped topic never registers', () async {
    final EventBus bus = eventBus((it) => it.topic(users))..dispose();

    final EventSubscription subscription = bus.topic(users).subscribe((_) {});

    expect(subscription.isActive, isFalse);
    await expectLater(subscription.awaitReady(), throwsStateError);
  });

  test('a declaration that fails starts nothing and reports it', () {
    expect(
      () => eventBus((it) {
        it
          ..topic(TopicKey<UserEvent>('a'), (it) => it.replay = -1)
          ..topic(TopicKey<AuditEvent>('b'), (it) => it.partitions = 0);
      }),
      throwsA(isA<ValidationException>()),
    );
  });

  test('a bus that was built does attach its topics', () {
    final EventBus bus = eventBus(
      (it) => it.topic(users, (it) => it.partitions = 3),
    );

    expect(bus.topic(users).partitionCount, 3);

    bus.dispose();
  });

  test('the bus reports the topics it was declared with', () {
    final EventBus bus = eventBus((it) {
      it
        ..topic(users)
        ..topic(audit);
    });

    expect(bus.topicNames, <String>['users', 'audit']);
    expect(bus.contains(users), isTrue);
    expect(bus.contains(audit), isTrue);
    expect(bus.topic(users).name, 'users');

    bus.dispose();
  });
}
