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
