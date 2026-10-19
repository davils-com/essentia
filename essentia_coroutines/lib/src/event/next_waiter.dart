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

import 'package:essentia_coroutines/src/event/event.dart';
import 'package:essentia_coroutines/src/event/event_envelope.dart';
import 'package:meta/meta.dart';

/// A caller of `EventTopic.next` waiting for the first envelope that
/// matches.
@internal
final class NextWaiter {
  /// Creates a waiter for the first envelope [_matches] accepts.
  NextWaiter(this._matches);

  /// Whether an envelope is the one waited for.
  final bool Function(EventEnvelope<Event> envelope) _matches;

  /// Completes with the envelope, or with an error when none will come.
  final _completer = Completer<EventEnvelope<Event>>();

  /// Completes with the envelope waited for.
  Future<EventEnvelope<Event>> get future => _completer.future;

  /// Takes [envelope] if it is the one waited for.
  ///
  /// Returns `true` when the waiter is satisfied and can be let go.
  bool offer(EventEnvelope<Event> envelope) {
    if (!_matches(envelope)) {
      return false;
    }
    _completer.complete(envelope);
    return true;
  }

  /// Fails the wait with [error], because no envelope will come.
  void abandon(Object error) {
    _completer.completeError(error);
  }
}
