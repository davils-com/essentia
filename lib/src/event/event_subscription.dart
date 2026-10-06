/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/event/subscriber.dart';
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
