/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/dsl/validating_builder.dart';
import 'package:essentia/src/event/event.dart';
import 'package:essentia/src/event/event_error_handler.dart';
import 'package:essentia/src/event/event_interceptor.dart';
import 'package:essentia/src/event/event_listener.dart';
import 'package:essentia/src/event/event_topic_data.dart';
import 'package:essentia/src/event/event_topic_defaults.dart';
import 'package:essentia/src/event/overflow_policy.dart';
import 'package:meta/meta.dart';

/// Configures one topic of a bus, carrying [T].
///
/// Every property starts at what the enclosing `EventBusBuilder` declared,
/// so a bus sets the shape of its topics once and a topic only says where it
/// differs.
///
/// ```dart
/// it.topic(users, (it) {
///   it.partitions = 4;
///   it.requiresKey = true;
///   it.replay = 10;
/// });
/// ```
final class EventTopicBuilder<T extends Event>
    extends ValidatingBuilder<EventTopicData<T>> {
  /// Creates the builder of the topic [_name], starting from [defaults].
  @internal
  EventTopicBuilder(this._name, EventTopicDefaults defaults)
    : replay = defaults.replay,
      bufferCapacity = defaults.bufferCapacity,
      partitions = defaults.partitions,
      requiresKey = defaults.requiresKey,
      overflow = defaults.overflow,
      listener = defaults.listener,
      onError = defaults.onError,
      _interceptors = <EventInterceptor>[...defaults.interceptors];

  /// The name of the topic.
  final String _name;

  /// The interceptors added so far, the bus's first.
  final List<EventInterceptor> _interceptors;

  /// How many envelopes a new subscriber is handed before anything published
  /// after it attaches.
  ///
  /// Zero, the default, means a subscriber sees only what happens from now
  /// on. Raising it is how a subscriber that attaches late still learns the
  /// current state, at the cost of the topic holding that many envelopes
  /// alive for as long as it exists. Must not be negative.
  int replay;

  /// How many envelopes one partition holds before [overflow] applies.
  ///
  /// This is per partition, so a topic with four partitions and a capacity
  /// of 64 holds up to 256. Must not be negative, and must be greater than
  /// zero unless [overflow] is [OverflowPolicy.suspend].
  int bufferCapacity;

  /// How many envelopes this topic can dispatch at once.
  ///
  /// One, the default, means the topic delivers strictly in publish order.
  /// Raising it keeps envelopes that share a key in order against each
  /// other, because a key always lands on the same partition, and lets
  /// everything else proceed independently of them.
  ///
  /// A consumer group runs one worker per partition, so raising this raises
  /// how much of that group runs at once. A single subscriber handles one
  /// envelope at a time however many partitions there are. Raising it on a
  /// topic whose publishers pass no key gives up ordering entirely; see
  /// [requiresKey]. Must be at least one.
  int partitions;

  /// Whether publishing to this topic without a key is refused.
  ///
  /// Set this on a topic that has more than one partition and cares about
  /// order. Without it, a publisher that forgets the key still succeeds and
  /// its envelopes are simply spread over the partitions, so the ordering is
  /// lost quietly rather than reported.
  bool requiresKey;

  /// What happens when a partition's buffer is full and a publisher will not
  /// wait.
  OverflowPolicy overflow;

  /// Where this topic reports what it did.
  EventListener listener;

  /// What handles a consumer of this topic that threw and declared no
  /// handler of its own.
  ///
  /// Defaults to doing nothing, in which case the failure is reported to
  /// [listener] and nowhere else.
  EventErrorHandler onError;

  /// What is being built, used in the headline of the report.
  @override
  String get subject => 'topic "$_name"';

  /// Adds [interceptor], which wraps each consumer of this topic handling
  /// each envelope.
  ///
  /// Appended after whatever the bus declared, and applied outermost first
  /// in the order they were added, so a bus-wide tracing interceptor is
  /// outside a topic's own.
  void intercept(EventInterceptor interceptor) {
    _interceptors.add(interceptor);
  }

  /// Puts together what the block configured.
  ///
  /// Returns the description of the topic.
  @override
  EventTopicData<T> assemble() => EventTopicData<T>(
    name: _name,
    replay: replay,
    bufferCapacity: bufferCapacity,
    partitions: partitions,
    requiresKey: requiresKey,
    overflow: overflow,
    listener: listener,
    interceptors: List<EventInterceptor>.unmodifiable(_interceptors),
    onError: onError,
  );
}
