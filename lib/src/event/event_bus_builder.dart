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
import 'package:essentia/src/event/event_violation_codes.dart';
import 'package:essentia/src/event/overflow_policy.dart';
import 'package:essentia/src/event/topic_key.dart';
import 'package:essentia/src/validation/validation_report.dart';
import 'package:essentia/src/validation/validation_scope.dart';
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

  /// The value behind [replay].
  var _replay = 0;

  /// The value behind [bufferCapacity].
  int _bufferCapacity = EventTopicDefaults.defaultBufferCapacity;

  /// The value behind [partitions].
  var _partitions = 1;

  /// The value behind [requiresKey].
  var _requiresKey = false;

  /// The value behind [overflow].
  OverflowPolicy _overflow = OverflowPolicy.suspend;

  /// The value behind [listener].
  EventListener _listener = EventListener.none;

  /// The value behind [onError].
  EventErrorHandler _onError = EventTopicDefaults.ignoreError;

  /// The defaults set after a topic was declared, each warned about once.
  final _lateDefaults = <String>{};

  /// The starting value for [EventTopicBuilder.replay] on every
  /// topic declared after this is set.
  ///
  /// A topic declared above keeps the value in force where it was written,
  /// and setting this after a topic produces a warning saying so.
  int get replay => _replay;

  /// Sets [replay] for every topic declared from here on.
  set replay(int value) {
    _replay = value;
    _noteLateDefault('replay');
  }

  /// The starting value for [EventTopicBuilder.bufferCapacity] on every
  /// topic declared after this is set.
  ///
  /// A topic declared above keeps the value in force where it was written,
  /// and setting this after a topic produces a warning saying so.
  int get bufferCapacity => _bufferCapacity;

  /// Sets [bufferCapacity] for every topic declared from here on.
  set bufferCapacity(int value) {
    _bufferCapacity = value;
    _noteLateDefault('bufferCapacity');
  }

  /// The starting value for [EventTopicBuilder.partitions] on every
  /// topic declared after this is set.
  ///
  /// A topic declared above keeps the value in force where it was written,
  /// and setting this after a topic produces a warning saying so.
  int get partitions => _partitions;

  /// Sets [partitions] for every topic declared from here on.
  set partitions(int value) {
    _partitions = value;
    _noteLateDefault('partitions');
  }

  /// The starting value for [EventTopicBuilder.requiresKey] on every
  /// topic declared after this is set.
  ///
  /// A topic declared above keeps the value in force where it was written,
  /// and setting this after a topic produces a warning saying so.
  bool get requiresKey => _requiresKey;

  /// Sets [requiresKey] for every topic declared from here on.
  set requiresKey(bool value) {
    _requiresKey = value;
    _noteLateDefault('requiresKey');
  }

  /// The starting value for [EventTopicBuilder.overflow] on every
  /// topic declared after this is set.
  ///
  /// A topic declared above keeps the value in force where it was written,
  /// and setting this after a topic produces a warning saying so.
  ///
  /// [OverflowPolicy.suspend], which is the default, is the only policy
  /// under which the bus never discards an envelope.
  OverflowPolicy get overflow => _overflow;

  /// Sets [overflow] for every topic declared from here on.
  set overflow(OverflowPolicy value) {
    _overflow = value;
    _noteLateDefault('overflow');
  }

  /// The starting value for [EventTopicBuilder.listener] on every
  /// topic declared after this is set.
  ///
  /// A topic declared above keeps the value in force where it was written,
  /// and setting this after a topic produces a warning saying so.
  ///
  /// This is where a listener normally goes: one implementation, told about
  /// every topic declared after it, rather than one per topic that has to
  /// be kept in step. Set it first.
  EventListener get listener => _listener;

  /// Sets [listener] for every topic declared from here on.
  set listener(EventListener value) {
    _listener = value;
    _noteLateDefault('listener');
  }

  /// The starting value for [EventTopicBuilder.onError] on every
  /// topic declared after this is set.
  ///
  /// A topic declared above keeps the value in force where it was written,
  /// and setting this after a topic produces a warning saying so.
  EventErrorHandler get onError => _onError;

  /// Sets [onError] for every topic declared from here on.
  set onError(EventErrorHandler value) {
    _onError = value;
    _noteLateDefault('onError');
  }

  /// What is being built, used in the headline of the report.
  @override
  String get subject => 'event bus';

  /// Adds [interceptor], which wraps every consumer of every topic handling
  /// every envelope.
  ///
  /// Applied outermost first in the order they were added, and always
  /// outside anything a topic adds for itself. A topic declared before this
  /// call does not get it, for the same reason it does not get a default set
  /// below it: a block means what it says where it is written. Adding one
  /// after a topic produces a warning saying so.
  void intercept(EventInterceptor interceptor) {
    _interceptors.add(interceptor);
    _noteLateDefault('intercept');
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

  /// Warns that [property] was set after a topic was declared, once per
  /// property: it does not reach the topics above it.
  void _noteLateDefault(String property) {
    if (_declared.isEmpty || !_lateDefaults.add(property)) {
      return;
    }
    final scope =
        ValidationScope(ViolationPath.root, EventViolationCodes.lateDefault)
          ..warn(
            '"$property" was set after a topic was declared and does not reach '
            'the topics above it',
            property: 'topics',
            code: EventViolationCodes.lateDefault,
          );
    adopt(scope.violations(), ViolationPath.root);
  }

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
