/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';
import 'dart:math';

import 'package:essentia/essentia.dart';
import 'package:test/test.dart';

import '../support/recording_listener.dart';
import '../support/topics.dart';
import '../support/user_event.dart';

/// How many partitions, and so how many workers, a partitioned topic has.
const _partitions = 4;

/// How many envelopes a test publishes.
const _publications = 40;

/// Reads the user an envelope is about.
///
/// Returns the user identifier.
String _identifier(EventEnvelope<UserEvent> envelope) =>
    envelope.payload.userId;

/// Lets every task that is ready run, so that what was published has been
/// handed to the workers.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

/// Tests consumer groups, the workers that share a topic out.
void main() {
  test('each envelope reaches exactly one worker of a group', () async {
    final EventBus bus = eventBus((it) {
      it.topic(users, (it) {
        it
          ..partitions = _partitions
          ..requiresKey = true;
      });
    });
    final handled = <String>[];
    bus
        .topic(users)
        .group('indexer', (envelope) => handled.add(_identifier(envelope)));

    for (var ordinal = 0; ordinal < _publications; ordinal++) {
      await bus
          .topic(users)
          .publish(Registered('u-$ordinal'), key: 'k${ordinal % 8}');
    }
    await bus.drain();

    expect(handled, hasLength(_publications));
    expect(handled.toSet(), hasLength(_publications));
  });

  test('a group runs one worker per partition', () {
    final EventBus bus = eventBus(
      (it) => it.topic(users, (it) => it.partitions = _partitions),
    );

    final ConsumerGroup group = bus.topic(users).group('indexer', (_) {});

    expect(group.name, 'indexer');
    expect(group.workerCount, _partitions);
    expect(group.isActive, isTrue);
    bus.dispose();
  });

  test('envelopes sharing a key reach the same worker, in publish '
      'order', () async {
    final EventBus bus = eventBus((it) {
      it.topic(users, (it) {
        it
          ..partitions = _partitions
          ..requiresKey = true;
      });
    });
    final perWorker = <(String, String)>[];
    bus
        .topic(users)
        .group(
          'indexer',
          (envelope) =>
              perWorker.add((envelope.key ?? '', _identifier(envelope))),
        );

    for (var ordinal = 0; ordinal < 30; ordinal++) {
      await bus.topic(users).publish(Registered('acme-$ordinal'), key: 'acme');
    }
    await bus.drain();

    final Iterable<String> forKey = perWorker
        .where((entry) => entry.$1 == 'acme')
        .map((entry) => entry.$2);
    expect(forKey, List<String>.generate(30, (ordinal) => 'acme-$ordinal'));
  });

  test('a group handles several envelopes at once across '
      'partitions', () async {
    final EventBus bus = eventBus(
      (it) => it.topic(users, (it) => it.partitions = _partitions),
    );
    final release = Completer<void>();
    var inFlight = 0;
    var peak = 0;

    bus.topic(users).group('indexer', (_) async {
      inFlight++;
      peak = max(peak, inFlight);
      await release.future;
      inFlight--;
    });

    for (var partition = 0; partition < _partitions; partition++) {
      await bus.topic(users).publish(Registered('u-$partition'));
    }
    await _settle();

    expect(peak, _partitions);
    release.complete();
    await bus.drain();
    expect(inFlight, 0);
  });

  test('a group and a subscriber on one topic do not see each other', () async {
    final EventBus bus = eventBus((it) => it.topic(users));
    final watched = <String>[];
    final worked = <String>[];

    final EventSubscription subscription = bus
        .topic(users)
        .subscribe((envelope) => watched.add(_identifier(envelope)));
    await subscription.awaitReady();
    bus
        .topic(users)
        .group('indexer', (envelope) => worked.add(_identifier(envelope)));

    for (var ordinal = 0; ordinal < 10; ordinal++) {
      await bus.topic(users).publish(Registered('u-$ordinal'));
    }
    await bus.drain();
    await subscription.join();

    final expected = List<String>.generate(10, (ordinal) => 'u-$ordinal');
    expect(watched, expected);
    expect(worked, expected);
  });

  test('two groups each get every envelope once', () async {
    final EventBus bus = eventBus(
      (it) => it.topic(users, (it) => it.partitions = 2),
    );
    final indexed = <String>[];
    final archived = <String>[];

    bus.topic(users)
      ..group('indexer', (envelope) => indexed.add(_identifier(envelope)))
      ..group('archiver', (envelope) => archived.add(_identifier(envelope)));

    for (var ordinal = 0; ordinal < 20; ordinal++) {
      await bus
          .topic(users)
          .publish(Registered('u-$ordinal'), key: 'k$ordinal');
    }
    await bus.drain();

    expect(indexed, hasLength(20));
    expect(archived, hasLength(20));
    expect(indexed.toSet(), archived.toSet());
  });

  test('a group needs no waiting before the first publication', () async {
    final EventBus bus = eventBus((it) => it.topic(users));
    final handled = <String>[];

    bus
        .topic(users)
        .group('indexer', (envelope) => handled.add(_identifier(envelope)));
    await bus.topic(users).publish(const Registered('first'));
    await bus.drain();

    expect(handled, <String>['first']);
  });

  test('a group attached later is not replayed to', () async {
    final EventBus bus = eventBus(
      (it) => it.topic(users, (it) => it.replay = 10),
    );
    final handled = <String>[];

    await bus.topic(users).publish(const Registered('before'));
    await _settle();

    bus
        .topic(users)
        .group('indexer', (envelope) => handled.add(_identifier(envelope)));
    await bus.topic(users).publish(const Registered('after'));
    await bus.drain();

    expect(handled, <String>['after']);
  });

  test('a worker that throws keeps the group going', () async {
    final EventBus bus = eventBus((it) => it.topic(users));
    final handled = <String>[];
    final failures = <Object>[];

    bus.topic(users).group('indexer', (envelope) {
      final String id = _identifier(envelope);
      handled.add(id);
      if (id == 'u-1') {
        throw StateError('no');
      }
    }, onError: (error, _) => failures.add(error));

    for (var ordinal = 0; ordinal < 4; ordinal++) {
      await bus.topic(users).publish(Registered('u-$ordinal'));
    }
    await bus.drain();

    expect(handled, List<String>.generate(4, (ordinal) => 'u-$ordinal'));
    expect(failures, <Matcher>[
      isA<StateError>().having((error) => error.message, 'message', 'no'),
    ]);
  });

  test('a group counts towards the topic metrics but not its '
      'subscribers', () {
    final EventBus bus = eventBus((it) => it.topic(users));
    final EventTopic<UserEvent> topic = bus.topic(users)
      ..group('indexer', (_) {});

    expect(topic.subscriberCount, 0);
    expect(topic.metrics.groups, 1);
    bus.dispose();
  });

  test('a group attached to a closed topic is never given anything', () async {
    final EventBus bus = eventBus((it) => it.topic(users))..dispose();
    final handled = <String>[];

    final ConsumerGroup group = bus
        .topic(users)
        .group('indexer', (envelope) => handled.add(_identifier(envelope)));
    await bus.topic(users).publish(const Registered('u-1'));
    await _settle();

    expect(handled, isEmpty);
    expect(group.isActive, isFalse);
  });

  group('detaching a group', () {
    test('stops it being given anything more', () async {
      final EventBus bus = eventBus((it) => it.topic(users));
      final handled = <String>[];
      final ConsumerGroup group = bus
          .topic(users)
          .group('indexer', (envelope) => handled.add(_identifier(envelope)));

      await bus.topic(users).publish(const Registered('before'));
      await _settle();

      await group.drain();
      await bus.topic(users).publish(const Registered('after'));
      await bus.drain();

      expect(handled, <String>['before']);
      expect(group.isActive, isFalse);
    });

    test('in an orderly way handles what it was already given', () async {
      final EventBus bus = eventBus((it) => it.topic(users));
      final handled = <String>[];
      final release = Completer<void>();
      final ConsumerGroup group = bus.topic(users).group('indexer', (
        envelope,
      ) async {
        await release.future;
        handled.add(_identifier(envelope));
      });

      for (var ordinal = 0; ordinal < 3; ordinal++) {
        await bus.topic(users).publish(Registered('u-$ordinal'));
      }
      await _settle();

      final Future<void> drained = group.drain();
      release.complete();
      await drained;

      expect(handled, <String>['u-0', 'u-1', 'u-2']);
      expect(group.isActive, isFalse);
      bus.dispose();
    });

    test('abruptly stops it at once', () {
      final EventBus bus = eventBus((it) => it.topic(users));
      final ConsumerGroup group = bus.topic(users).group('indexer', (_) {})
        ..cancel();

      expect(group.isActive, isFalse);
      expect(bus.topic(users).metrics.groups, 0);
      bus.dispose();
    });

    test('abruptly reports what it was still holding', () async {
      final listener = RecordingListener();
      final EventBus bus = eventBus((it) {
        it
          ..listener = listener
          ..topic(users);
      });
      final handled = <String>[];
      final release = Completer<void>();
      final ConsumerGroup group = bus.topic(users).group('indexer', (
        envelope,
      ) async {
        handled.add(_identifier(envelope));
        await release.future;
      });

      for (var ordinal = 0; ordinal < 3; ordinal++) {
        await bus.topic(users).publish(Registered('u-$ordinal'));
      }
      await _settle();

      group.cancel();
      release.complete();
      await _settle();

      expect(handled, <String>['u-0']);
      expect(
        listener.dropped.map((entry) => entry.$1.payload),
        const <UserEvent>[Registered('u-1'), Registered('u-2')],
      );
      expect(listener.dropReasons, <DropReason>[
        DropReason.disposed,
        DropReason.disposed,
      ]);
      expect(group.isActive, isFalse);
      bus.dispose();
    });
  });

  test('the listener is told which group did the work', () async {
    final listener = RecordingListener();
    final EventBus bus = eventBus((it) {
      it
        ..listener = listener
        ..topic(users);
    });
    bus.topic(users).group('indexer', (_) {});

    await bus.topic(users).publish(const Registered('u-1'));
    await bus.drain();

    expect(listener.delivered.map((entry) => entry.$2), <String>['indexer']);
  });
}
