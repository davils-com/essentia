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

import 'dart:async';
import 'dart:math';

import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:test/test.dart';

import '../support/recording_listener.dart';
import '../support/topics.dart';
import '../support/user_event.dart';

/// How many keys are published under.
const _keys = 4;

/// How many envelopes are published under each key.
const _perKey = 50;

/// How many partitions the ordered topic dispatches on.
const _partitions = 4;

/// Tests the order envelopes are delivered in.
void main() {
  test('envelopes sharing a key arrive in publish order, whatever else is '
      'going on', () async {
    final EventBus bus = eventBus((it) {
      it.topic(users, (it) {
        it
          ..partitions = _partitions
          ..requiresKey = true;
      });
    });
    final received = <(String, int)>[];
    final EventSubscription subscription = bus.topic(users).subscribe((
      envelope,
    ) {
      final String userId = envelope.payload.userId;
      final int ordinal = int.parse(
        userId.substring(userId.lastIndexOf('-') + 1),
      );
      received.add((envelope.key ?? '', ordinal));
    });
    await subscription.awaitReady();

    for (var ordinal = 0; ordinal < _perKey; ordinal++) {
      for (var key = 0; key < _keys; key++) {
        await bus
            .topic(users)
            .publish(Registered('k$key-$ordinal'), key: 'k$key');
      }
    }
    await bus.drain();
    await subscription.join();

    expect(received, hasLength(_keys * _perKey));
    for (var key = 0; key < _keys; key++) {
      final Iterable<int> forKey = received
          .where((entry) => entry.$1 == 'k$key')
          .map((entry) => entry.$2);
      expect(forKey, List<int>.generate(_perKey, (ordinal) => ordinal));
    }
  });

  test('envelopes sharing a key arrive in publish order when published '
      'without waiting', () async {
    final EventBus bus = eventBus((it) {
      it.topic(users, (it) {
        it
          ..partitions = _partitions
          ..requiresKey = true
          ..bufferCapacity = _keys * _perKey;
      });
    });
    final received = <(String, int)>[];
    final EventSubscription subscription = bus.topic(users).subscribe((
      envelope,
    ) {
      final String userId = envelope.payload.userId;
      final int ordinal = int.parse(
        userId.substring(userId.lastIndexOf('-') + 1),
      );
      received.add((envelope.key ?? '', ordinal));
    });

    for (var ordinal = 0; ordinal < _perKey; ordinal++) {
      for (var key = 0; key < _keys; key++) {
        bus.topic(users).tryPublish(Registered('k$key-$ordinal'), key: 'k$key');
      }
    }
    await bus.drain();
    await subscription.join();

    expect(received, hasLength(_keys * _perKey));
    for (var key = 0; key < _keys; key++) {
      final Iterable<int> forKey = received
          .where((entry) => entry.$1 == 'k$key')
          .map((entry) => entry.$2);
      expect(forKey, List<int>.generate(_perKey, (ordinal) => ordinal));
    }
  });

  test('a topic with one partition orders everything, key or no key', () async {
    final EventBus bus = eventBus((it) => it.topic(users));
    final received = <String>[];
    final EventSubscription subscription = bus
        .topic(users)
        .subscribe((envelope) => received.add(envelope.payload.userId));
    await subscription.awaitReady();

    final published = List<String>.generate(100, (ordinal) => 'u-$ordinal');
    for (final id in published) {
      await bus.topic(users).publish(Registered(id), key: id);
    }
    await bus.drain();
    await subscription.join();

    expect(received, published);
  });

  test('a key always lands on the same partition', () async {
    final EventBus bus = eventBus((it) {
      it.topic(users, (it) {
        it
          ..partitions = 8
          ..requiresKey = true;
      });
    });
    final received = <String>[];
    final EventSubscription subscription = bus
        .topic(users)
        .subscribe((envelope) => received.add(envelope.payload.userId));
    await subscription.awaitReady();

    await bus
        .topic(users)
        .publish(const Registered('first'), key: 'tenant-acme');
    for (var noise = 0; noise < 20; noise++) {
      await bus
          .topic(users)
          .publish(Registered('noise-$noise'), key: 'tenant-$noise');
    }
    await bus
        .topic(users)
        .publish(const Registered('second'), key: 'tenant-acme');
    await bus.drain();
    await subscription.join();

    final Iterable<String> forTenant = received.where(
      (id) => id == 'first' || id == 'second',
    );
    expect(forTenant, <String>['first', 'second']);
  });

  test('publications with no key are spread over the partitions rather than '
      'piling onto one', () async {
    final listener = RecordingListener();
    final EventBus bus = eventBus((it) {
      it
        ..listener = listener
        ..topic(users, (it) => it.partitions = 4);
    });

    for (var ordinal = 0; ordinal < 40; ordinal++) {
      await bus.topic(users).publish(Registered('u-$ordinal'));
    }
    await bus.drain();

    expect(listener.published, hasLength(40));
    expect(listener.dropped, isEmpty);
  });

  test('publications with no key are dealt out turn about, one to each '
      'partition', () async {
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

    for (var ordinal = 0; ordinal < _partitions; ordinal++) {
      await bus.topic(users).publish(Registered('u-$ordinal'));
    }
    await Future<void>.delayed(Duration.zero);

    expect(peak, _partitions);
    release.complete();
    await bus.drain();
    expect(inFlight, 0);
  });
}
