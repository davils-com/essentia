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

import 'package:essentia_coroutines/src/event/event.dart';
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

  /// The topic's name.
  final String name;

  /// The payload type, kept so that a bus can refuse a key that names one of
  /// its topics but disagrees about what it carries.
  Type get eventType => T;

  /// Two keys are the same key when they name the same topic **and** agree
  /// on what it carries, which is what a bus checks when it resolves one.
  @override
  bool operator ==(Object other) =>
      other is TopicKey && name == other.name && eventType == other.eventType;

  /// The hash of the name and the payload type.
  @override
  int get hashCode => Object.hash(name, eventType);

  /// Renders the key as `TopicKey(users: UserEvent)`.
  @override
  String toString() => 'TopicKey($name: $T)';
}
