/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia_core/essentia_core.dart';
import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:essentia_coroutines/testing.dart';
import 'package:test/test.dart';

import '../support/topics.dart';
import '../support/user_event.dart';

/// Covers the event bus on coroutines: a publisher waiting for room is
/// cancellable, and the lanes and consumers are coroutines that end with
/// the topic.
void main() {
  test(
    'a publisher waiting for room stops when its job is cancelled',
    () => runTest((it) async {
      final blocked = Completer<void>();
      final EventBus bus = eventBus(
        (it) => it.topic(users, (it) => it.bufferCapacity = 1),
      );
      bus.topic(users).subscribe((_) => blocked.future);
      final Job publishing = it.launch((it) async {
        for (var index = 0; index < 5; index++) {
          await bus.topic(users).publish(Registered('u-$index'));
        }
      });
      it.runCurrent();
      final bool waiting = publishing.isActive;

      await publishing.cancelAndJoin();

      expect(waiting, isTrue);
      expect(publishing.isCancelled, isTrue);
      blocked.complete();
      bus.dispose();
    }),
  );

  test(
    'a consumer runs as a coroutine, as the principal that subscribed',
    () => runTest((it) async {
      final seen = <String>[];
      final EventBus bus = eventBus((it) => it.topic(users));
      runAsPrincipal(
        principal('indexer'),
        () => bus.topic(users).subscribe((_) {
          final Job? job = currentCoroutineContext().get(Job.key);
          seen.add('${currentPrincipal()?.id} ${job?.isActive}');
        }),
      );
      it.runCurrent();

      await bus.topic(users).publish(const Registered('u-1'));
      await bus.drain();

      expect(seen, <String>['indexer true']);
    }),
  );

  test(
    'disposing a topic ends its consumers',
    () => runTest((it) async {
      final EventBus bus = eventBus((it) => it.topic(users));
      final EventSubscription subscription = bus.topic(users).subscribe((_) {});
      final ConsumerGroup group = bus.topic(users).group('indexer', (_) {});
      it.runCurrent();

      bus.dispose();
      await subscription.join();
      await group.drain();

      expect(subscription.isActive, isFalse);
      expect(group.isActive, isFalse);
    }),
  );
}
