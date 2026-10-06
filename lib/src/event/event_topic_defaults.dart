/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/event/event_error_handler.dart';
import 'package:essentia/src/event/event_interceptor.dart';
import 'package:essentia/src/event/event_listener.dart';
import 'package:essentia/src/event/overflow_policy.dart';
import 'package:meta/meta.dart';

/// What a bus declared for every topic declared after it, which a topic
/// starts from.
@internal
@immutable
final class EventTopicDefaults {
  /// Creates the defaults; every value left out is the bus's own default.
  const EventTopicDefaults({
    this.replay = 0,
    this.bufferCapacity = defaultBufferCapacity,
    this.partitions = 1,
    this.requiresKey = false,
    this.overflow = OverflowPolicy.suspend,
    this.listener = EventListener.none,
    this.interceptors = const <EventInterceptor>[],
    this.onError = ignoreError,
  });

  /// How many envelopes one partition holds unless something else is
  /// declared.
  static const defaultBufferCapacity = 64;

  /// The default for a topic's replay.
  final int replay;

  /// The default for a topic's buffer capacity.
  final int bufferCapacity;

  /// The default for a topic's partition count.
  final int partitions;

  /// The default for whether a topic requires a key.
  final bool requiresKey;

  /// The default for a topic's overflow policy.
  final OverflowPolicy overflow;

  /// The default for a topic's listener.
  final EventListener listener;

  /// The interceptors every topic starts with.
  final List<EventInterceptor> interceptors;

  /// The default for a topic's error handler.
  final EventErrorHandler onError;

  /// The error handler that does nothing, which leaves a failure reported
  /// to the listener and nowhere else.
  static void ignoreError(Object error, StackTrace stackTrace) {}
}
