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

import 'package:essentia_coroutines/essentia_coroutines.dart';
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
