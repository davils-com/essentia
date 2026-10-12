/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:test/test.dart';

import '../support/recording_listener.dart';
import '../support/topics.dart';
import '../support/user_event.dart';

/// How many envelopes a partition of the topics under test holds.
const _capacity = 4;

/// Reads the user every dropped envelope recorded by [listener] is about.
///
/// Returns the users, in the order they were dropped.
List<String> _droppedUsers(RecordingListener listener) => <String>[
  for (final (EventEnvelope<Event> envelope, DropReason _) in listener.dropped)
    if (envelope.payload case UserEvent(:final String userId)) userId,
];

/// Declares a bus carrying the user topic with a buffer of [_capacity]
/// under [overflow], reporting to [listener].
///
/// Returns the bus.
EventBus _busWith(OverflowPolicy overflow, RecordingListener listener) =>
    eventBus((it) {
      it
        ..listener = listener
        ..topic(users, (it) {
          it
            ..bufferCapacity = _capacity
            ..overflow = overflow;
        });
    });

/// Checks what a topic does when its buffer is full.
void main() {
  group('when the buffer is full and the publisher will not wait', () {
    test('suspending refuses the new one and keeps what is queued', () {
      final listener = RecordingListener();
      final EventBus bus = _busWith(OverflowPolicy.suspend, listener);

      final List<EventEnvelope<UserEvent>?> accepted = [
        for (var ordinal = 0; ordinal < _capacity + 3; ordinal++)
          bus.topic(users).tryPublish(Registered('u-$ordinal')),
      ];

      expect(accepted.nonNulls, hasLength(_capacity + 1));
      expect(accepted.last, isNull);
      expect(listener.dropReasons.toSet(), <DropReason>{DropReason.overflow});
      expect(_droppedUsers(listener), <String>['u-5', 'u-6']);
      bus.dispose();
    });

    test('dropping the latest refuses the new one and reports it', () {
      final listener = RecordingListener();
      final EventBus bus = _busWith(OverflowPolicy.dropLatest, listener);

      final List<EventEnvelope<UserEvent>?> accepted = [
        for (var ordinal = 0; ordinal < _capacity + 3; ordinal++)
          bus.topic(users).tryPublish(Registered('u-$ordinal')),
      ];

      expect(accepted.nonNulls, hasLength(_capacity + 1));
      expect(_droppedUsers(listener), <String>['u-5', 'u-6']);
      expect(listener.dropReasons.toSet(), <DropReason>{DropReason.overflow});
      bus.dispose();
    });

    test(
      'dropping the oldest accepts the new one and reports what it evicted',
      () {
        final listener = RecordingListener();
        final EventBus bus = _busWith(OverflowPolicy.dropOldest, listener);

        final List<EventEnvelope<UserEvent>?> accepted = [
          for (var ordinal = 0; ordinal < _capacity + 3; ordinal++)
            bus.topic(users).tryPublish(Registered('u-$ordinal')),
        ];

        expect(accepted, everyElement(isNotNull));
        expect(accepted.last, isNotNull);
        expect(_droppedUsers(listener), <String>['u-1', 'u-2']);
        expect(listener.dropReasons.toSet(), <DropReason>{DropReason.overflow});
        bus.dispose();
      },
    );

    test('the counters agree with what the listener was told', () {
      final listener = RecordingListener();
      final EventBus bus = _busWith(OverflowPolicy.dropOldest, listener);

      for (var ordinal = 0; ordinal < _capacity + 3; ordinal++) {
        bus.topic(users).tryPublish(Registered('u-$ordinal'));
      }

      final TopicMetrics metrics = bus.topic(users).metrics;
      expect(metrics.published, _capacity + 3);
      expect(metrics.dropped, listener.dropped.length);
      expect(metrics.queueDepth, _capacity);
      bus.dispose();
    });
  });

  test(
    'a publisher that waits is never subject to the overflow policy',
    () async {
      final listener = RecordingListener();
      final EventBus bus = _busWith(OverflowPolicy.dropOldest, listener);
      final received = <String>[];
      final EventSubscription subscription = bus
          .topic(users)
          .subscribe((it) => received.add(it.payload.userId));
      await subscription.awaitReady();

      final published = List<String>.generate(
        _capacity * 5,
        (index) => 'u-$index',
      );
      for (final id in published) {
        await bus.topic(users).publish(Registered(id));
      }
      await bus.drain();
      await subscription.join();

      expect(received, published);
      expect(listener.dropped, isEmpty);
    },
  );

  test('a topic with no buffer at all hands over directly', () async {
    final EventBus bus = eventBus((it) {
      it.topic(users, (it) {
        it
          ..bufferCapacity = 0
          ..overflow = OverflowPolicy.suspend;
      });
    });
    final received = <String>[];
    final EventSubscription subscription = bus
        .topic(users)
        .subscribe((it) => received.add(it.payload.userId));
    await subscription.awaitReady();

    await bus.topic(users).publish(const Registered('u-1'));
    await bus.topic(users).publish(const Registered('u-2'));
    await bus.drain();
    await subscription.join();

    expect(received, <String>['u-1', 'u-2']);
  });
}
