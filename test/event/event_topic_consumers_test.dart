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

import '../support/topics.dart';
import '../support/user_event.dart';

/// Tests whether a topic says an envelope published now would reach
/// anybody.
void main() {
  test('a topic nobody consumes says so', () {
    final EventBus bus = eventBus((it) => it.topic(users));

    expect(bus.topic(users).hasConsumers, isFalse);

    bus.dispose();
  });

  test('a broadcast subscriber is a consumer for as long as it is '
      'attached', () async {
    final EventBus bus = eventBus((it) => it.topic(users));
    final EventSubscription subscription = bus.topic(users).subscribe((_) {});
    await subscription.awaitReady();

    expect(bus.topic(users).hasConsumers, isTrue);

    await subscription.cancelAndJoin();
    expect(bus.topic(users).hasConsumers, isFalse);
    bus.dispose();
  });

  test('a caller waiting for the next envelope is a consumer', () async {
    final EventBus bus = eventBus((it) => it.topic(users));
    final Future<EventEnvelope<UserEvent>> waiting = bus.topic(users).next();
    await pumpEventQueue();

    expect(bus.topic(users).hasConsumers, isTrue);

    bus.dispose();
    await expectLater(waiting, throwsStateError);
  });

  test('a consumer group is a consumer, though it counts as no '
      'subscriber', () {
    final EventBus bus = eventBus((it) => it.topic(users));
    final ConsumerGroup group = bus.topic(users).group('indexer', (_) {});

    expect(bus.topic(users).subscriberCount, 0);
    expect(bus.topic(users).hasConsumers, isTrue);

    group.cancel();
    bus.dispose();
  });

  test('a replay cache is a consumer, because it hands the envelope to '
      'whoever attaches later', () {
    final EventBus bus = eventBus(
      (it) => it.topic(users, (it) => it.replay = 1),
    );

    expect(bus.topic(users).hasConsumers, isTrue);

    bus.dispose();
  });

  test('a closed topic has no consumers, whatever was attached', () async {
    final EventBus bus = eventBus(
      (it) => it.topic(users, (it) => it.replay = 1),
    );
    await bus.topic(users).subscribe((_) {}).awaitReady();

    bus.dispose();

    expect(bus.topic(users).hasConsumers, isFalse);
  });
}
