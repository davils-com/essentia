/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/event/event.dart';
import 'package:essentia/src/event/event_error_handler.dart';
import 'package:essentia/src/event/event_interceptor.dart';
import 'package:essentia/src/event/event_listener.dart';
import 'package:essentia/src/event/event_topic.dart';
import 'package:essentia/src/event/event_topic_defaults.dart';
import 'package:essentia/src/event/event_violation_codes.dart';
import 'package:essentia/src/event/overflow_policy.dart';
import 'package:essentia/src/validation/validatable.dart';
import 'package:essentia/src/validation/validation_scope.dart';
import 'package:meta/meta.dart';

/// What a topic carrying [T] was declared to be.
///
/// The assembled result of one `EventTopicBuilder`, and a description
/// rather than a running thing: nothing here has a task attached, which is
/// what lets a declaration be put together, found wrong and thrown away
/// without anything needing to be cleaned up. `EventBusData.topics` is a
/// list of these, and [EventTopic] is what one becomes once the bus starts
/// it.
///
/// Every property is the value the builder settled on, so the builder
/// documents what each one is worth choosing and this documents what it
/// means once chosen.
@immutable
final class EventTopicData<T extends Event> implements Validatable {
  /// Creates the description of the topic [name].
  @internal
  const EventTopicData({
    required this.name,
    required this.replay,
    required this.bufferCapacity,
    required this.partitions,
    required this.requiresKey,
    required this.overflow,
    required this.listener,
    required this.interceptors,
    required this.onError,
  });

  /// What this topic is called, unique within a bus.
  final String name;

  /// How many envelopes a new subscriber is handed before anything published
  /// after it attaches.
  ///
  /// Zero means a subscriber sees only what happens from now on. Must not be
  /// negative.
  final int replay;

  /// How many envelopes one partition holds before [overflow] applies.
  ///
  /// Per partition rather than per topic. Must not be negative, and must be
  /// greater than zero unless [overflow] is [OverflowPolicy.suspend]: with
  /// no room to buffer, a publisher that does not wait can only reach a
  /// subscriber that is already waiting for it.
  final int bufferCapacity;

  /// How many envelopes this topic can dispatch at once.
  ///
  /// One means the topic delivers strictly in publish order. Above one,
  /// envelopes sharing a key stay ordered against each other because a key
  /// always lands on the same partition. Must be at least one.
  final int partitions;

  /// Whether publishing to this topic without a key is refused.
  ///
  /// Has no effect on a topic with one partition, where every envelope is
  /// already ordered against every other.
  final bool requiresKey;

  /// What happens when a partition's buffer is full and a publisher will not
  /// wait.
  final OverflowPolicy overflow;

  /// Where this topic reports what it did.
  final EventListener listener;

  /// What wraps each consumer of this topic handling each envelope.
  ///
  /// In the order they were added, applied outermost first, with whatever
  /// the bus declared ahead of the topic's own.
  final List<EventInterceptor> interceptors;

  /// What handles a consumer of this topic that threw and declared no
  /// handler of its own.
  final EventErrorHandler onError;

  /// The type of event this topic carries.
  ///
  /// Publishing anything else is refused, which is what makes a topic typed
  /// rather than a name with a convention attached to it.
  Type get eventType => T;

  /// States what is wrong with this declaration.
  @override
  void validate(ValidationScope scope) {
    if (replay < 0) {
      scope.fail(
        'must not be negative',
        property: 'replay',
        code: EventViolationCodes.invalidReplay,
      );
    }
    if (replay > EventTopicDefaults.maxReplay) {
      scope.fail(
        'must not exceed ${EventTopicDefaults.maxReplay}, because every '
        'replayed envelope is held for as long as the topic exists',
        property: 'replay',
        code: EventViolationCodes.invalidReplay,
      );
    }
    if (bufferCapacity > EventTopicDefaults.maxBufferCapacity) {
      scope.fail(
        'must not exceed ${EventTopicDefaults.maxBufferCapacity}, because a '
        'buffer that large holds back no publisher',
        property: 'bufferCapacity',
        code: EventViolationCodes.invalidBuffer,
      );
    }
    if (bufferCapacity < 0) {
      scope.fail(
        'must not be negative',
        property: 'bufferCapacity',
        code: EventViolationCodes.invalidBuffer,
      );
    }
    final bool needsRoom =
        bufferCapacity == 0 && overflow != OverflowPolicy.suspend;
    if (needsRoom) {
      scope.fail(
        'must be greater than zero unless the overflow policy is suspend, '
        'because with no room to buffer, a publisher that does not wait can '
        'only reach a subscriber that is already waiting for it',
        property: 'bufferCapacity',
        code: EventViolationCodes.invalidBuffer,
      );
    }
    if (partitions < 1) {
      scope.fail(
        'must be at least one',
        property: 'partitions',
        code: EventViolationCodes.invalidPartitions,
      );
    }
    if (partitions > EventTopicDefaults.maxPartitions) {
      scope.fail(
        'must not exceed ${EventTopicDefaults.maxPartitions}, because every '
        'partition is a mailbox and a task, and every consumer group adds '
        'that many again',
        property: 'partitions',
        code: EventViolationCodes.invalidPartitions,
      );
    }
    if (requiresKey && partitions == 1) {
      scope.warn(
        'has no effect on a topic with one partition, where every envelope '
        'is already ordered against every other',
        property: 'requiresKey',
        code: EventViolationCodes.keyWithoutPartitions,
      );
    }
  }

  /// Starts the topic this declaration describes.
  ///
  /// Returns the running topic.
  @internal
  EventTopic<T> toTopic() => EventTopic<T>(this);
}
