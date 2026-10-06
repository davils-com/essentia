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

import '../support/recording_listener.dart';
import '../support/topics.dart';
import '../support/user_event.dart';

/// How many publishers run at once.
const _publishers = 8;

/// How many envelopes each publisher publishes.
const _perPublisher = 250;

/// How many partitions the topic under test has.
const _partitions = 4;

/// Declares a bus carrying the user topic over [_partitions] partitions of
/// [capacity] each, requiring a key and reporting to [listener].
///
/// Returns the bus.
EventBus _busWith(int capacity, EventListener listener) => eventBus((it) {
  it
    ..listener = listener
    ..topic(users, (it) {
      it
        ..partitions = _partitions
        ..requiresKey = true
        ..bufferCapacity = capacity;
    });
});

/// Runs [_publishers] publishers onto the user topic of [bus] at once, each
/// publishing [_perPublisher] registrations under its own key and yielding
/// to the others between publications.
Future<void> _publishConcurrently(EventBus bus) async {
  final EventTopic<UserEvent> topic = bus.topic(users);
  await Future.wait(<Future<void>>[
    for (var publisher = 0; publisher < _publishers; publisher++)
      Future<void>(() async {
        for (var ordinal = 0; ordinal < _perPublisher; ordinal++) {
          await topic.publish(
            Registered('p$publisher-$ordinal'),
            key: 'p$publisher',
          );
          if (ordinal.isEven) {
            await Future<void>.delayed(Duration.zero);
          }
        }
      }),
  ]);
}

/// Records the user of [envelope] in [handled], sometimes after yielding so
/// that consumers interleave with the publishers.
///
/// Returns once it is recorded.
Future<void> _record(
  EventEnvelope<UserEvent> envelope,
  List<String> handled,
) async {
  if (envelope.payload.userId.hashCode.isOdd) {
    await Future<void>.delayed(Duration.zero);
  }
  handled.add(envelope.payload.userId);
}

/// Checks that interleaved publishers and consumers lose and reorder
/// nothing.
void main() {
  test(
    'nothing is lost when several publishers publish to one topic at once',
    () async {
      final listener = RecordingListener();
      final EventBus bus = _busWith(16, listener);
      final handled = <String>[];
      bus.topic(users).group('worker', (it) => _record(it, handled));

      await _publishConcurrently(bus);
      await bus.drain();

      const int expected = _publishers * _perPublisher;
      expect(handled, hasLength(expected));
      expect(handled.toSet(), hasLength(expected));
      expect(listener.dropped, isEmpty);
      expect(bus.topic(users).metrics.published, expected);
      expect(bus.topic(users).metrics.delivered, expected);
    },
  );

  test('each key keeps its own order across concurrent publishers', () async {
    final EventBus bus = _busWith(16, EventListener.none);
    final handled = <String>[];
    bus.topic(users).group('worker', (it) => _record(it, handled));

    await _publishConcurrently(bus);
    await bus.drain();

    for (var publisher = 0; publisher < _publishers; publisher++) {
      expect(
        handled.where((it) => it.startsWith('p$publisher-')),
        List<String>.generate(
          _perPublisher,
          (ordinal) => 'p$publisher-$ordinal',
        ),
      );
    }
  });

  test(
    'a subscriber and a group both keep up with several publishers',
    () async {
      final EventBus bus = _busWith(32, EventListener.none);
      final watched = <String>[];
      final worked = <String>[];
      final EventSubscription subscription = bus
          .topic(users)
          .subscribe((it) => _record(it, watched));
      await subscription.awaitReady();
      bus.topic(users).group('worker', (it) => _record(it, worked));

      await _publishConcurrently(bus);
      await bus.drain();
      await subscription.join();

      const int expected = _publishers * _perPublisher;
      expect(watched, hasLength(expected));
      expect(worked, hasLength(expected));
    },
  );
}
