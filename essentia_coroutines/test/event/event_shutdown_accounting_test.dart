/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:test/test.dart';

import '../support/recording_listener.dart';
import '../support/topics.dart';
import '../support/user_event.dart';
import 'broken_exporter_listener.dart';

/// How many envelopes the accounting tests publish.
const _published = 6;

/// How many of them a blocked subscriber and the partition delivering to it
/// hold while the topic is disposed: the one being handled and the one
/// waiting to be handed over.
const _inFlight = 2;

/// Checks that a topic stopped under load accounts for every envelope.
void main() {
  test('everything buffered when a topic is disposed is reported, and none of '
      'it is delivered', () async {
    final listener = RecordingListener();
    final blocked = Completer<void>();
    final EventBus bus = eventBus((it) {
      it
        ..listener = listener
        ..topic(users, (it) => it.bufferCapacity = 8);
    });
    final EventTopic<UserEvent> topic = bus.topic(users);
    await topic.subscribe((_) => blocked.future, name: 'slow').awaitReady();

    for (var index = 0; index < _published; index++) {
      await topic.publish(Registered('u-$index'));
    }
    await pumpEventQueue();

    bus.dispose();
    await pumpEventQueue();

    expect(listener.delivered, isEmpty);
    expect(listener.dropReasons.toSet(), <DropReason>{DropReason.disposed});
    expect(
      listener.dropped.map((it) => it.$1.id).toSet(),
      hasLength(listener.dropped.length),
    );
    expect(listener.dropped, hasLength(_published - _inFlight));
    blocked.complete();
  });

  test('what the partition already took when the topic is disposed is reported '
      'too', () async {
    final listener = RecordingListener();
    final EventBus bus = eventBus((it) {
      it
        ..listener = listener
        ..topic(users, (it) => it.bufferCapacity = 16);
    });
    final EventTopic<UserEvent> topic = bus.topic(users);

    final List<EventEnvelope<UserEvent>?> accepted = [
      for (var ordinal = 0; ordinal < 10; ordinal++)
        topic.tryPublish(Registered('u-$ordinal')),
    ];
    bus.dispose();
    await pumpEventQueue();

    expect(
      listener.dropped.map((it) => it.$1.id).toSet(),
      accepted.nonNulls.map((it) => it.id).toSet(),
    );
    expect(listener.dropReasons.toSet(), <DropReason>{DropReason.disposed});
    expect(topic.metrics.dropped, 10);
    expect(listener.delivered, isEmpty);
  });

  test('a full partition settles at its capacity', () async {
    final blocked = Completer<void>();
    final EventBus bus = eventBus(
      (it) => it.topic(users, (it) => it.bufferCapacity = 1),
    );
    final EventTopic<UserEvent> topic = bus.topic(users);
    await topic.subscribe((_) => blocked.future).awaitReady();

    for (var index = 0; index < _inFlight + 1; index++) {
      await topic.publish(Registered('u-$index'));
    }
    await pumpEventQueue();

    expect(topic.metrics.queueDepth, 1);

    bus.dispose();
    blocked.complete();
  });

  test('a publisher waiting for room when the topic is disposed is not left '
      'waiting and its envelope is accounted for', () async {
    final listener = RecordingListener();
    final blocked = Completer<void>();
    final EventBus bus = eventBus((it) {
      it
        ..listener = listener
        ..topic(users, (it) => it.bufferCapacity = 1);
    });
    final EventTopic<UserEvent> topic = bus.topic(users);
    await topic.subscribe((_) => blocked.future).awaitReady();
    for (var index = 0; index < _inFlight + 1; index++) {
      await topic.publish(Registered('u-$index'));
    }
    await pumpEventQueue();

    final Future<EventEnvelope<UserEvent>?> waiting = topic.publish(
      const Registered('has-nowhere-to-go'),
    );
    await pumpEventQueue();
    bus.dispose();
    await waiting;

    final droppedUsers = <String>[
      for (final (EventEnvelope<Event> envelope, DropReason _)
          in listener.dropped)
        if (envelope.payload case UserEvent(:final String userId)) userId,
    ];
    expect(droppedUsers, contains('has-nowhere-to-go'));
    expect(topic.metrics.queueDepth, 0);
    blocked.complete();
  });

  test(
    'a listener that throws on publish and on drop cannot break the topic',
    () async {
      final EventBus bus = eventBus((it) {
        it
          ..listener = const BrokenExporterListener()
          ..topic(users, (it) => it.bufferCapacity = 4);
      });
      final EventTopic<UserEvent> topic = bus.topic(users);

      expect(await topic.publish(const Registered('u-1')), isNotNull);
      expect(topic.tryPublish(const Registered('u-2')), isNotNull);
      await pumpEventQueue();

      bus.dispose();

      expect(topic.state, BusState.closed);
      expect(await topic.publish(const Registered('u-3')), isNull);
      expect(topic.metrics.published, 2);
      expect(topic.metrics.dropped, 1);
    },
  );
}
