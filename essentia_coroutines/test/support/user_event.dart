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

  /// Renders the event with its field.
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

  /// Renders the event with its fields.
  @override
  String toString() => 'Deleted(userId=$userId, reason=$reason)';
}
