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

/// How many envelopes a partition and a group mailbox each hold.
const _capacity = 64;

/// How many envelopes are published.
const _published = 70;

/// How many envelopes the fast group handled before it was cancelled: the
/// one the slow group's worker holds and the [_capacity] its mailbox
/// buffers.
const int _reachedBeforeCancel = _capacity + 1;

/// Reads the user an envelope is about.
///
/// Returns the user identifier.
String _userIdOf(EventEnvelope<Event> envelope) =>
    (envelope.payload as UserEvent).userId;

/// Tests how consumer groups behave when they or their topic stop.
void main() {
  group('an envelope on its way to a group whose mailbox closed', () {
    test('is reported to the listener as closed rather than lost', () async {
      final listener = RecordingListener();
      final EventBus bus = eventBus((it) {
        it
          ..listener = listener
          ..topic(users, (it) => it.bufferCapacity = _capacity);
      });
      final EventTopic<UserEvent> topic = bus.topic(users);
      final gate = Completer<void>();
      final fastSeen = <String>[];
      topic.group('slow', (_) => gate.future);
      final ConsumerGroup fast = topic.group(
        'fast',
        (envelope) => fastSeen.add(_userIdOf(envelope)),
      );
      for (var index = 0; index < _published; index++) {
        await topic.publish(Registered('u-$index'));
      }
      await pumpEventQueue();

      fast.cancel();
      gate.complete();
      await pumpEventQueue();

      expect(fastSeen, hasLength(_reachedBeforeCancel));
      expect(listener.dropped.map((entry) => _userIdOf(entry.$1)), <String>[
        'u-$_reachedBeforeCancel',
      ]);
      expect(listener.dropReasons, <DropReason>[DropReason.closed]);
      expect(topic.metrics.dropped, 1);
      bus.dispose();
    });
  });

  group('attaching a group', () {
    test('to a disposed topic is refused', () {
      final EventBus bus = eventBus((it) => it.topic(users))..dispose();

      expect(
        () => bus.topic(users).group('late', (_) {}),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Topic "users" is closed and takes no new consumer group, so '
                '"late" was not attached',
          ),
        ),
      );
    });

    test('to a drained topic is refused', () async {
      final EventBus bus = eventBus((it) => it.topic(users));
      await bus.drain();

      expect(() => bus.topic(users).group('late', (_) {}), throwsStateError);
    });

    test("that was refused is not counted among the topic's groups", () {
      final EventBus bus = eventBus((it) => it.topic(users))..dispose();

      expect(() => bus.topic(users).group('late', (_) {}), throwsStateError);

      expect(bus.topic(users).metrics.groups, 0);
    });
  });
}
