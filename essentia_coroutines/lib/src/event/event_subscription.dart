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

import 'package:essentia_coroutines/src/event/subscriber.dart';
import 'package:meta/meta.dart';

/// A handle on one attachment to a topic.
///
/// A subscription is registered with its topic before `subscribe` returns,
/// so everything published afterwards reaches it. [awaitReady] is kept for
/// code that wants to say so explicitly, and fails for a subscription that
/// never registered because its topic was already closed.
final class EventSubscription {
  /// Creates the handle of [_subscriber].
  @internal
  const EventSubscription(this._subscriber);

  /// The attachment this handle controls.
  final Subscriber _subscriber;

  /// What this subscription is called, which is the name it is reported
  /// under to the bus's listener.
  String get name => _subscriber.name;

  /// Whether this subscription is still receiving.
  bool get isActive => _subscriber.isActive;

  /// Completes once this subscription is registered with its topic.
  ///
  /// Everything published after this completes reaches this subscription.
  ///
  /// Throws a [StateError] if the topic was closed before the subscription
  /// could register.
  Future<void> awaitReady() async {
    if (!_subscriber.isRegistered) {
      throw StateError(
        'Subscription "$name" never registered: its topic was already '
        'closed',
      );
    }
  }

  /// Stops this subscription without waiting for it to finish what it is
  /// holding.
  void cancel() {
    _subscriber.cancel();
  }

  /// Stops this subscription and completes once it has finished.
  Future<void> cancelAndJoin() {
    _subscriber.cancel();
    return _subscriber.done;
  }

  /// Completes once this subscription ends by itself.
  ///
  /// Only a subscription that has an end completes: one made by
  /// `subscribeOnce`, or any of them once the topic closes. Joining a plain
  /// subscription that nothing cancels waits forever, which is the correct
  /// answer to the question.
  Future<void> join() => _subscriber.done;
}
