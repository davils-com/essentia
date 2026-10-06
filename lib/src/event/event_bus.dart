/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/event/bus_state.dart';
import 'package:essentia/src/event/event.dart';
import 'package:essentia/src/event/event_bus_builder.dart';
import 'package:essentia/src/event/event_bus_data.dart';
import 'package:essentia/src/event/event_topic.dart';
import 'package:essentia/src/event/event_topic_data.dart';
import 'package:essentia/src/event/topic_key.dart';
import 'package:essentia/src/event/topic_not_declared_error.dart';
import 'package:essentia/src/event/topic_type_mismatch_error.dart';
import 'package:essentia/src/lifecycle/disposable.dart';
import 'package:essentia/src/scope/scope_functions.dart';
import 'package:essentia/src/validation/validation_exception.dart';
import 'package:meta/meta.dart';

/// A set of typed topics that share a lifetime and a listener.
///
/// A bus is declared once, in full, through [eventBus]. Its topics are fixed
/// from that moment: none can be added, removed or reconfigured while it
/// runs. That is deliberate: a topic that can appear at any time is a topic
/// whose subscribers cannot be reasoned about.
///
/// A failure inside one topic never reaches its siblings.
///
/// ```dart
/// final users = TopicKey<UserEvent>('users');
///
/// final EventBus bus = eventBus((it) => it.topic(users, (it) {
///   it.partitions = 4;
/// }));
///
/// bus.topic(users).subscribe((it) => print(it.payload));
/// await bus.topic(users).publish(const UserRegistered('u-42'), key: 'u-42');
/// ```
final class EventBus implements Disposable {
  /// Starts every topic [data] declares.
  @internal
  EventBus(EventBusData data)
    : _topics = Map<String, EventTopic<Event>>.unmodifiable(
        <String, EventTopic<Event>>{
          for (final EventTopicData<Event> topic in data.topics)
            topic.name: topic.toTopic(),
        },
      );

  /// The running topics by name, in the order they were declared.
  final Map<String, EventTopic<Event>> _topics;

  /// Where the bus is in its life.
  BusState _lifecycle = BusState.running;

  /// Where the bus is in its life.
  ///
  /// A topic disposed on its own does not change this. The bus's state is
  /// about the bus.
  BusState get state => _lifecycle;

  /// The names of every topic on this bus, in the order they were declared.
  ///
  /// For diagnostics. Resolving a topic goes through its key, not through a
  /// name looked up here.
  Set<String> get topicNames => Set<String>.unmodifiable(_topics.keys);

  /// Resolves the topic [key] names.
  ///
  /// The payload type travels with the key, so what comes back is already
  /// typed and nothing has to be cast at the call site.
  ///
  /// Returns the live topic.
  ///
  /// Throws a [TopicNotDeclaredError] if this bus does not carry the topic
  /// the key names, and a [TopicTypeMismatchError] if it does but declared
  /// it to carry something else, which means two keys name it and disagree.
  EventTopic<T> topic<T extends Event>(TopicKey<T> key) {
    final EventTopic<Event>? topic = _topics[key.name];
    if (topic == null) {
      throw TopicNotDeclaredError(key.name, topicNames);
    }
    if (topic is! EventTopic<T> || topic.eventType != key.eventType) {
      throw TopicTypeMismatchError(key.name, topic.eventType, key.eventType);
    }
    return topic;
  }

  /// Whether this bus carries the topic [key] names.
  bool contains(TopicKey<Event> key) => _topics.containsKey(key.name);

  /// Stops every topic at once, without delivering what they still hold.
  ///
  /// Calling this again does nothing.
  @override
  void dispose() {
    if (_lifecycle == BusState.closed) {
      return;
    }
    _lifecycle = BusState.closed;
    for (final EventTopic<Event> topic in _topics.values) {
      topic.dispose();
    }
  }

  /// Stops every topic after it has delivered everything it is still
  /// holding.
  ///
  /// Topics are drained one after another rather than at once, so a
  /// subscriber publishing onto a topic declared after its own still gets
  /// through. Declaration order is therefore also the order to shut down in,
  /// which is why it is preserved. Calling this again waits for the first
  /// call to finish.
  Future<void> drain() async {
    if (_lifecycle != BusState.running) {
      await _drainTopics();
      return;
    }
    _lifecycle = BusState.draining;
    await _drainTopics();
    _lifecycle = BusState.closed;
  }

  /// Drains every topic, in the order they were declared.
  Future<void> _drainTopics() async {
    for (final EventTopic<Event> topic in _topics.values) {
      await topic.drain();
    }
  }
}

/// Declares and starts an event bus, configured by [block].
///
/// The block declares every topic the bus will ever carry. It is checked as
/// a whole before anything starts running, so a declaration with three
/// mistakes in it reports all three at once and leaves nothing running.
///
/// ```dart
/// final users = TopicKey<UserEvent>('users');
/// final audit = TopicKey<AuditEvent>('audit');
///
/// final EventBus bus = eventBus((it) {
///   it.listener = MetricsListener(registry);
///   it.topic(users, (it) {
///     it.partitions = 4;
///     it.requiresKey = true;
///   });
///   it.topic(audit, (it) => it.replay = 50);
/// });
/// ```
///
/// Returns a bus with every declared topic ready to publish to and
/// subscribe on.
///
/// Throws a [ValidationException] carrying every problem found if the
/// declaration is wrong, and an [ArgumentError] if a topic is declared
/// twice.
EventBus eventBus(void Function(EventBusBuilder it) block) =>
    EventBus(EventBusBuilder().apply(block).build());
