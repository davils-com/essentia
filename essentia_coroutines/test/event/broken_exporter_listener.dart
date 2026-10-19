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

/// A listener whose exporter is down, so that every notification throws.
final class BrokenExporterListener extends EventListener {
  /// Creates the listener.
  const BrokenExporterListener();

  /// What every notification throws.
  static const message = 'exporter is down';

  /// Throws instead of recording [envelope] as published.
  @override
  void onPublished(EventEnvelope<Event> envelope) {
    throw StateError(message);
  }

  /// Throws instead of recording [envelope] as delivered to [consumer].
  @override
  void onDelivered(EventEnvelope<Event> envelope, String consumer) {
    throw StateError(message);
  }

  /// Throws instead of recording [envelope] as failed in [consumer] with
  /// [failure] and [stackTrace].
  @override
  void onFailed(
    EventEnvelope<Event> envelope,
    String consumer,
    Object failure,
    StackTrace stackTrace,
  ) {
    throw StateError(message);
  }

  /// Throws instead of recording [envelope] as dropped for [reason].
  @override
  void onDropped(EventEnvelope<Event> envelope, DropReason reason) {
    throw StateError(message);
  }
}
