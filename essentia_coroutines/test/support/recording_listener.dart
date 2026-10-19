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

/// A listener that records everything it is told, for the event tests.
final class RecordingListener extends EventListener {
  /// The envelopes reported as published.
  final published = <EventEnvelope<Event>>[];

  /// The envelopes reported as delivered, with their consumer.
  final delivered = <(EventEnvelope<Event>, String)>[];

  /// The envelopes reported as failed, with their consumer and failure.
  final failed = <(EventEnvelope<Event>, String, Object)>[];

  /// The envelopes reported as dropped, with the reason.
  final dropped = <(EventEnvelope<Event>, DropReason)>[];

  /// The reasons of every drop, in order.
  List<DropReason> get dropReasons => dropped.map((entry) => entry.$2).toList();

  /// Records [envelope] as published.
  @override
  void onPublished(EventEnvelope<Event> envelope) {
    published.add(envelope);
  }

  /// Records [envelope] as delivered to [consumer].
  @override
  void onDelivered(EventEnvelope<Event> envelope, String consumer) {
    delivered.add((envelope, consumer));
  }

  /// Records [envelope] as failed in [consumer] with [failure].
  @override
  void onFailed(
    EventEnvelope<Event> envelope,
    String consumer,
    Object failure,
    StackTrace stackTrace,
  ) {
    failed.add((envelope, consumer, failure));
  }

  /// Records [envelope] as dropped for [reason].
  @override
  void onDropped(EventEnvelope<Event> envelope, DropReason reason) {
    dropped.add((envelope, reason));
  }
}
