/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia/essentia.dart';
import 'package:test/test.dart';

import '../support/topics.dart';
import '../support/user_event.dart';

/// How many partitions the topic under test has.
const _partitions = 4;

/// How many times the set of colliding keys is doubled.
const _collidingPairs = 6;

/// How many envelopes one partition of a topic with a buffer of one holds
/// in front of a blocked group: one in the partition's buffer, one held by
/// its delivery task, one in the group's mailbox and one in its worker.
const _heldPerPartition = 4;

/// How many candidate blocks one search step tries before giving up.
const int _candidates = 1 << 20;

/// Two suffixes that tell a collision of the hasher's internal state apart
/// from a chance collision of the finished hash.
const _probes = <String>['Z', 'q7'];

/// Keys that all share one `String.hashCode`, found once per run.
final List<String> _collidingKeys = _keysWithOneStringHashCode();

/// Searches, after [prefix], for two four character blocks that leave the
/// string hasher in the same state, so that every string continuing either
/// of them the same way has the same `String.hashCode`.
///
/// Returns the two blocks.
///
/// Throws a [StateError] if no such pair is found among the candidates.
(String, String) _collidingBlocks(String prefix) {
  final seen = <int, String>{};
  for (var candidate = 0; candidate < _candidates; candidate++) {
    final String block = candidate.toRadixString(36).padLeft(4, '0');
    final hash = (prefix + block).hashCode;
    final String? earlier = seen[hash];
    final bool sameState =
        earlier != null &&
        _probes.every(
          (probe) =>
              (prefix + earlier + probe).hashCode ==
              (prefix + block + probe).hashCode,
        );
    if (sameState) {
      return (earlier, block);
    }
    seen[hash] = block;
  }
  throw StateError('No two blocks after "$prefix" share a hasher state');
}

/// Builds `2^_collidingPairs` keys sharing one `String.hashCode`, the way
/// Arc builds them from `Aa` and `BB`: every step finds two blocks that
/// leave the hasher in the same state and doubles the keys with them.
///
/// Returns the keys.
List<String> _keysWithOneStringHashCode() {
  var keys = <String>[''];
  for (var step = 0; step < _collidingPairs; step++) {
    final (String one, String other) = _collidingBlocks(keys.first);
    keys = <String>[
      for (final key in keys) ...<String>[key + one, key + other],
    ];
  }
  return keys;
}

/// Tests that keys are spread over the partitions by a hash of their own,
/// not by `String.hashCode`.
void main() {
  test('the colliding keys used here really do share one '
      'String.hashCode', () {
    expect(_collidingKeys.map((key) => key.hashCode).toSet(), hasLength(1));
    expect(_collidingKeys.toSet(), hasLength(64));
  });

  test('keys that collide under String.hashCode are not all dispatched on '
      'one partition', () async {
    final gate = Completer<void>();
    final EventBus bus = eventBus((it) {
      it.topic(users, (it) {
        it
          ..partitions = _partitions
          ..bufferCapacity = 1;
      });
    });
    final EventTopic<UserEvent> topic = bus.topic(users)
      ..group('blocked', (_) => gate.future);

    var accepted = 0;
    for (final String key in _collidingKeys) {
      if (topic.tryPublish(Registered(key), key: key) != null) {
        accepted++;
      }
      await pumpEventQueue();
    }

    expect(accepted, greaterThan(_heldPerPartition));
    bus.dispose();
  });

  test('many keys are spread over every partition', () async {
    final release = Completer<void>();
    final EventBus bus = eventBus((it) {
      it.topic(users, (it) {
        it
          ..partitions = _partitions
          ..bufferCapacity = 512;
      });
    });
    var inFlight = 0;
    bus.topic(users).group('worker', (_) async {
      inFlight++;
      await release.future;
    });

    for (var ordinal = 0; ordinal < 256; ordinal++) {
      await bus
          .topic(users)
          .publish(Registered('u-$ordinal'), key: 'tenant-$ordinal');
    }
    await pumpEventQueue();

    expect(inFlight, _partitions);
    release.complete();
    await bus.drain();
  });

  test('equal keys still keep their order on a topic with several '
      'partitions', () async {
    final handled = <String>[];
    final EventBus bus = eventBus(
      (it) => it.topic(users, (it) => it.partitions = _partitions),
    );
    bus
        .topic(users)
        .group('worker', (envelope) => handled.add(envelope.payload.userId));
    final String key = _collidingKeys.first;

    for (var index = 0; index < 10; index++) {
      await bus.topic(users).publish(Registered('$key-$index'), key: key);
    }
    await bus.drain();

    expect(handled, List<String>.generate(10, (index) => '$key-$index'));
  });
}
