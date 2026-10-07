/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:math';

import 'package:essentia/essentia.dart';
import 'package:essentia/testing.dart';
import 'package:test/test.dart';

import 'channel_model.dart';

/// The channels the property is checked on: how `Channel()` is called and
/// the capacity and overflow it resolves to.
const _configurations =
    <
      ({
        String name,
        int capacity,
        BufferOverflow overflow,
        int resolved,
        BufferOverflow resolvedOverflow,
      })
    >[
      (
        name: 'rendezvous',
        capacity: Channel.rendezvous,
        overflow: BufferOverflow.suspend,
        resolvedOverflow: BufferOverflow.suspend,
        resolved: 0,
      ),
      (
        name: 'one element',
        capacity: 1,
        overflow: BufferOverflow.suspend,
        resolvedOverflow: BufferOverflow.suspend,
        resolved: 1,
      ),
      (
        name: 'three elements',
        capacity: 3,
        overflow: BufferOverflow.suspend,
        resolvedOverflow: BufferOverflow.suspend,
        resolved: 3,
      ),
      (
        name: 'unlimited',
        capacity: Channel.unlimited,
        overflow: BufferOverflow.suspend,
        resolvedOverflow: BufferOverflow.suspend,
        resolved: Channel.unlimited,
      ),
      (
        name: 'conflated',
        capacity: Channel.conflated,
        overflow: BufferOverflow.suspend,
        resolvedOverflow: BufferOverflow.dropOldest,
        resolved: 1,
      ),
      (
        name: 'two elements dropping the oldest',
        capacity: 2,
        overflow: BufferOverflow.dropOldest,
        resolvedOverflow: BufferOverflow.dropOldest,
        resolved: 2,
      ),
      (
        name: 'two elements dropping the latest',
        capacity: 2,
        overflow: BufferOverflow.dropLatest,
        resolvedOverflow: BufferOverflow.dropLatest,
        resolved: 2,
      ),
      (
        name: 'rendezvous dropping the oldest',
        capacity: Channel.rendezvous,
        overflow: BufferOverflow.dropOldest,
        resolvedOverflow: BufferOverflow.dropOldest,
        resolved: 1,
      ),
    ];

/// How many random runs each channel gets.
const _runs = 30;

/// How many operations one run takes.
const _steps = 60;

/// Runs [_steps] random operations, drawn from [random], on a channel
/// made as [configuration] describes and on its [ChannelModel], checking
/// after every step that both agree, and at the end that every element
/// sent met exactly one fate.
Future<void> _check(
  TestScope scope,
  ({
    String name,
    int capacity,
    BufferOverflow overflow,
    int resolved,
    BufferOverflow resolvedOverflow,
  })
  configuration,
  Random random,
) async {
  final model = ChannelModel(
    configuration.resolved,
    configuration.resolvedOverflow,
  );
  final undelivered = <int>[];
  final channel = Channel<int>(
    capacity: configuration.capacity,
    onBufferOverflow: configuration.overflow,
    onUndeliveredElement: undelivered.add,
  );
  final deliveries = <({int receiver, int element})>[];
  final closedReceivers = <int>{};
  final senderOutcomes = <int, String>{};
  final senderJobs = <int, Job>{};
  final receiverJobs = <int, Job>{};
  final accepted = <int>[];
  var next = 0;

  /// Applies the operation [choice] picks, numbered [id].
  void operate(int choice, int id) {
    if (choice < 25) {
      accepted.add(id);
      model.send(id, id);
      senderJobs[id] = scope.launch(start: CoroutineStart.undispatched, (
        it,
      ) async {
        try {
          await channel.send(id);
          senderOutcomes[id] = 'sent';
        } on Object {
          senderOutcomes[id] = 'failed';
        }
      });
      return;
    }
    if (choice < 40) {
      final ChannelResult<void> expected = model.trySend(id);
      final ChannelResult<void> actual = channel.trySend(id);
      expect(actual.isSuccess, expected.isSuccess, reason: 'trySend($id)');
      expect(actual.isClosed, expected.isClosed, reason: 'trySend($id)');
      if (actual.isSuccess) {
        accepted.add(id);
      }
      return;
    }
    if (choice < 60) {
      model.receive(id);
      receiverJobs[id] = scope.launch(start: CoroutineStart.undispatched, (
        it,
      ) async {
        final ChannelResult<int> result = await channel.receiveCatching();
        if (result.isSuccess) {
          deliveries.add((receiver: id, element: result.getOrThrow()));
          return;
        }
        closedReceivers.add(id);
      });
      return;
    }
    if (choice < 75) {
      final bool closedForReceive = model.isClosedForReceive;
      final int? expected = model.tryReceive();
      final ChannelResult<int> actual = channel.tryReceive();
      expect(actual.getOrNull(), expected, reason: 'tryReceive()');
      expect(actual.isClosed, closedForReceive, reason: 'tryReceive()');
      if (expected != null) {
        model.deliveries.add((receiver: -1, element: expected));
        deliveries.add((receiver: -1, element: actual.getOrThrow()));
      }
      return;
    }
    if (choice < 85 && model.senders.isNotEmpty) {
      final int sender =
          model.senders[random.nextInt(model.senders.length)].sender;
      model.cancelSender(sender);
      senderJobs[sender]?.cancel();
      return;
    }
    if (choice < 95 && model.receivers.isNotEmpty) {
      final int receiver =
          model.receivers[random.nextInt(model.receivers.length)];
      model.cancelReceiver(receiver);
      receiverJobs[receiver]?.cancel();
      return;
    }
    if (choice < 98) {
      model.close();
      channel.close();
      return;
    }
    model.cancel();
    channel.cancel();
  }

  for (var step = 0; step < _steps; step++) {
    final int choice = random.nextInt(100);
    final int id = next++;
    operate(choice, id);
    await yieldNow();
    expect(deliveries, model.deliveries, reason: 'after step $step');
    expect(undelivered, model.undelivered, reason: 'after step $step');
    expect(closedReceivers, model.closedReceivers, reason: 'after $step');
    expect(senderOutcomes, model.senderOutcomes, reason: 'after $step');
    expect(channel.isClosedForReceive, model.isClosedForReceive);
  }
  model.cancel();
  channel.cancel();
  await yieldNow();
  final received = <int>[for (final delivery in deliveries) delivery.element];
  expect(received, orderedEquals(List<int>.of(received)..sort()));
  expect(
    [...received, ...undelivered, ...model.dropped]..sort(),
    accepted,
    reason: 'every element sent meets exactly one fate',
  );
}

/// Covers the channel against a pure reference queue: random sends,
/// receives, closes, cancellations and cancelled waiters, checking that
/// every element sent is received exactly once or reported undelivered
/// exactly once, in the order it was sent.
void main() {
  for (final ({
        String name,
        int capacity,
        BufferOverflow overflow,
        int resolved,
        BufferOverflow resolvedOverflow,
      })
      configuration
      in _configurations) {
    test(
      'a ${configuration.name} channel behaves like its reference queue',
      () => runTest((it) async {
        for (var run = 0; run < _runs; run++) {
          await _check(it, configuration, Random(run));
        }
      }),
    );
  }
}
