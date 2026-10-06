/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/event/event.dart';
import 'package:meta/meta.dart';

/// The name of a topic and the type [T] of what it transports, as one
/// value.
///
/// A key is declared where the topics of an application are declared, and
/// the bus is told about it afterwards. It is an ordinary value with no
/// reference to any bus, so it can be a top level `final` wherever the
/// code that publishes and the code that consumes can both see it.
///
/// ```dart
/// final users = TopicKey<UserEvent>('users');
/// final audit = TopicKey<AuditEvent>('audit');
///
/// final EventBus bus = eventBus((it) {
///   it.topic(users, (it) => it.partitions = 4);
///   it.topic(audit);
/// });
///
/// await bus.topic(users).publish(const UserRegistered('u-42'), key: 'u-42');
/// ```
///
/// Declaring the key separately is what keeps the bus declaration from
/// having to hand anything back out of its block. The type travels with the
/// key, so resolving one gives a topic that is already typed and nothing
/// has to be cast at the call site.
@immutable
final class TopicKey<T extends Event> {
  /// Creates the key of the topic [name] carrying [T].
  ///
  /// Throws an [ArgumentError] if [name] is blank.
  TopicKey(this.name) {
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', 'A topic name must not be blank');
    }
  }

  /// The topic's name. Two keys naming the same topic are the same key.
  final String name;

  /// The payload type, kept so that a bus can refuse a key that names one of
  /// its topics but disagrees about what it carries.
  Type get eventType => T;

  /// Two keys are equal when they name the same topic.
  @override
  bool operator ==(Object other) => other is TopicKey && name == other.name;

  /// The hash of the name.
  @override
  int get hashCode => name.hashCode;

  /// Renders the key as `TopicKey(users: UserEvent)`.
  @override
  String toString() => 'TopicKey($name: $T)';
}
