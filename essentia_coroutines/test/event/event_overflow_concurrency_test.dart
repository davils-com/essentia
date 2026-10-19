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

import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:test/test.dart';

import '../support/recording_listener.dart';
import '../support/topics.dart';
import '../support/user_event.dart';

/// How many publishers run at once.
const _publishers = 8;

/// How many envelopes each publisher offers.
const _perPublisher = 500;

/// How many envelopes the partition buffers.
const _capacity = 4;

/// Offers [_perPublisher] registrations to [topic] as the publisher
/// numbered [publisher], without waiting, yielding to the other publishers
/// every few offers.
///
/// Returns how many were accepted.
Future<int> _offerConcurrently(
  EventTopic<UserEvent> topic,
  int publisher,
) async {
  var accepted = 0;
  for (var index = 0; index < _perPublisher; index++) {
    if (topic.tryPublish(Registered('t$publisher-$index')) != null) {
      accepted++;
    }
    if (index % 8 == 0) {
      await Future<void>.delayed(Duration.zero);
    }
  }
  return accepted;
}

/// Checks that interleaved publishers that will not wait account for every
/// envelope on a full topic.
void main() {
  test('publishers that will not wait on a full drop-oldest topic all return '
      'and account for everything', () async {
    final listener = RecordingListener();
    final gate = Completer<void>();
    final EventBus bus = eventBus((it) {
      it
        ..listener = listener
        ..topic(users, (it) {
          it
            ..bufferCapacity = _capacity
            ..overflow = OverflowPolicy.dropOldest;
        });
    });
    final EventTopic<UserEvent> topic = bus.topic(users);
    await topic.subscribe((_) => gate.future).awaitReady();

    final List<int> perPublisher = await Future.wait(<Future<int>>[
      for (var publisher = 0; publisher < _publishers; publisher++)
        _offerConcurrently(topic, publisher),
    ]);
    final int accepted = perPublisher.fold(0, (sum, count) => sum + count);
    final int refused = _publishers * _perPublisher - accepted;
    final Iterable<DropReason> overflowed = listener.dropReasons.where(
      (reason) => reason == DropReason.overflow,
    );

    expect(topic.metrics.published, accepted);
    expect(overflowed.length, greaterThanOrEqualTo(refused));
    expect(listener.dropReasons.length, overflowed.length);
    expect(topic.metrics.queueDepth, _capacity);
    gate.complete();
    bus.dispose();
  });
}
