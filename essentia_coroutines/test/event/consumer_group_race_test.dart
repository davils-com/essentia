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

import '../support/topics.dart';

/// How many times each interleaving is tried.
const _attempts = 50;

/// Attaches the group `racer` to the user topic of [bus].
///
/// Returns the group.
ConsumerGroup _attach(EventBus bus) => bus.topic(users).group('racer', (_) {});

/// Tests a group attached while its topic is being disposed, with both
/// scheduled as separate tasks of the event loop in either order.
void main() {
  test('a group attached while its topic is being disposed is refused when '
      'the dispose runs first', () async {
    for (var attempt = 0; attempt < _attempts; attempt++) {
      final EventBus bus = eventBus((it) => it.topic(users));
      final stopping = Future<void>(bus.dispose);
      final Future<void> refused = expectLater(
        Future<ConsumerGroup>(() => _attach(bus)),
        throwsStateError,
      );

      await stopping;
      await refused;
    }
  });

  test('a group attached while its topic is being disposed is torn down when '
      'the attach runs first, never left running', () async {
    for (var attempt = 0; attempt < _attempts; attempt++) {
      final EventBus bus = eventBus((it) => it.topic(users));
      final attaching = Future<ConsumerGroup>(() => _attach(bus));
      final stopping = Future<void>(bus.dispose);

      await stopping;
      final ConsumerGroup group = await attaching;

      expect(group.isActive, isFalse);
    }
  });
}
