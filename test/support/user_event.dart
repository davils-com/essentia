/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';
import 'package:meta/meta.dart';

/// What happens to a user, the sealed hierarchy the event tests publish.
@immutable
sealed class UserEvent implements Event {
  /// Creates an event about the user [userId].
  const UserEvent(this.userId);

  /// The user the event is about.
  final String userId;
}

/// A user registered.
final class Registered extends UserEvent {
  /// Creates the registration of [userId].
  const Registered(super.userId);

  /// Two registrations are equal when they are about the same user.
  @override
  bool operator ==(Object other) =>
      other is Registered && userId == other.userId;

  /// The hash of the user.
  @override
  int get hashCode => Object.hash(Registered, userId);

  /// Renders the event the way a Kotlin data class does.
  @override
  String toString() => 'Registered(userId=$userId)';
}

/// A user was deleted.
final class Deleted extends UserEvent {
  /// Creates the deletion of [userId] for [reason].
  const Deleted(super.userId, this.reason);

  /// Why the user was deleted.
  final String reason;

  /// Two deletions are equal when their user and reason are.
  @override
  bool operator ==(Object other) =>
      other is Deleted && userId == other.userId && reason == other.reason;

  /// The hash of the user and the reason.
  @override
  int get hashCode => Object.hash(Deleted, userId, reason);

  /// Renders the event the way a Kotlin data class does.
  @override
  String toString() => 'Deleted(userId=$userId, reason=$reason)';
}
