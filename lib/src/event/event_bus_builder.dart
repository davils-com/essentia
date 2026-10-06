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
import 'package:essentia/src/event/event_bus_data.dart';
import 'package:essentia/src/event/event_error_handler.dart';
import 'package:essentia/src/event/event_interceptor.dart';
import 'package:essentia/src/event/event_listener.dart';
import 'package:essentia/src/event/event_topic_builder.dart';
import 'package:essentia/src/event/event_topic_data.dart';
import 'package:essentia/src/event/event_topic_defaults.dart';
import 'package:essentia/src/event/overflow_policy.dart';
import 'package:essentia/src/event/topic_key.dart';
import 'package:essentia/src/validation/validation_report.dart';
import 'package:essentia/src/validation/violation.dart';
import 'package:essentia/src/validation/violation_path.dart';
import 'package:meta/meta.dart';

/// Declares the topics a bus carries and what they have in common.
///
/// Every property here is the starting value for every topic declared after
/// it, and a topic overrides what it needs to. A bus that wants all of its
/// topics observed sets [listener] once rather than on each of them.
///
/// ```dart
/// final users = TopicKey<UserEvent>('users');
/// final audit = TopicKey<AuditEvent>('audit');
///
/// final EventBus bus = eventBus((it) {
///   it.listener = MetricsListener(registry);
///   it.bufferCapacity = 256;
///
///   it.topic(users, (it) {
///     it.partitions = 4;
///     it.requiresKey = true;
///   });
///   it.topic(audit);
/// });
/// ```
///
/// Nothing declared here starts running. The builder assembles a
/// description, [build] checks all of it, and only a description that came
/// out sound is turned into a bus, so a declaration with a mistake in it
/// reports every mistake it has and leaves nothing running behind.
final class EventBusBuilder extends ValidatingBuilder<EventBusData> {
  /// Creates an empty declaration.
  @internal
  EventBusBuilder();

  /// The topics declared so far.
  final _declared = <EventTopicData<Event>>[];

  /// The names declared so far.
  final _names = <String>{};

  /// The interceptors added so far.
  final _interceptors = <EventInterceptor>[];

  /// The default for every topic's [EventTopicBuilder.replay].
  var replay = 0;

  /// The default for every topic's [EventTopicBuilder.bufferCapacity].
  int bufferCapacity = EventTopicDefaults.defaultBufferCapacity;

  /// The default for every topic's [EventTopicBuilder.partitions].
  var partitions = 1;

  /// The default for every topic's [EventTopicBuilder.requiresKey].
  var requiresKey = false;

  /// The default for every topic's [EventTopicBuilder.overflow].
  ///
  /// [OverflowPolicy.suspend], which is the default, is the only policy
  /// under which the bus never discards an envelope.
  OverflowPolicy overflow = OverflowPolicy.suspend;

  /// The default for every topic's [EventTopicBuilder.listener].
  ///
  /// This is where a listener normally goes: one implementation, told about
  /// every topic, rather than one per topic that has to be kept in step.
  EventListener listener = EventListener.none;

  /// The default for every topic's [EventTopicBuilder.onError].
  EventErrorHandler onError = EventTopicDefaults.ignoreError;

  /// What is being built, used in the headline of the report.
  @override
  String get subject => 'event bus';

  /// Adds [interceptor], which wraps every consumer of every topic handling
  /// every envelope.
  ///
  /// Applied outermost first in the order they were added, and always
  /// outside anything a topic adds for itself. A topic declared before this
  /// call does not get it, for the same reason it does not get a default set
  /// below it: a block means what it says where it is written.
  void intercept(EventInterceptor interceptor) {
    _interceptors.add(interceptor);
  }

  /// Declares the topic [key] names, configured by [block] starting from
  /// this builder's defaults.
  ///
  /// A name already declared is refused here and now rather than collected
  /// into the report, because it can be nothing but a mistake in the
  /// source, unlike a capacity, which may well have come from a
  /// configuration file.
  ///
  /// Throws an [ArgumentError] if the key's name has already been declared
  /// on this bus.
  void topic<T extends Event>(
    TopicKey<T> key, [
    void Function(EventTopicBuilder<T> it)? block,
  ]) {
    if (!_names.add(key.name)) {
      throw ArgumentError.value(
        key.name,
        'key',
        'Topic "${key.name}" is already declared on this bus',
      );
    }
    final builder = EventTopicBuilder<T>(key.name, _currentDefaults());
    block?.call(builder);
    final ({ValidationReport report, EventTopicData<T> value}) evaluation =
        builder.evaluate();
    _declared.add(evaluation.value);
    final List<Violation> violations = evaluation.report.violations;
    if (violations.isNotEmpty) {
      final ViolationPath at = ViolationPath.of('topics')
          .index(_declared.length - 1);
      adopt(violations, at);
    }
  }

  /// Puts together what the block declared.
  ///
  /// Returns the description of the bus.
  @override
  EventBusData assemble() => EventBusData(_declared);

  /// The defaults as they stand at this point of the block.
  ///
  /// Returns what the next topic starts from.
  EventTopicDefaults _currentDefaults() => EventTopicDefaults(
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
