/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/event/event.dart';
import 'package:essentia/src/event/event_topic_data.dart';
import 'package:essentia/src/event/event_violation_codes.dart';
import 'package:essentia/src/validation/validatable.dart';
import 'package:essentia/src/validation/validation_scope.dart';
import 'package:meta/meta.dart';

/// What a bus was declared to be.
///
/// Like the topics it holds, this is a description and not a running thing.
/// Nothing here has a task attached, which is the property that lets a
/// declaration be assembled, found wrong and thrown away without anything
/// having to be cleaned up afterwards.
@immutable
final class EventBusData implements Validatable {
  /// Creates the description of a bus carrying [topics].
  @internal
  EventBusData(List<EventTopicData<Event>> topics)
    : topics = List<EventTopicData<Event>>.unmodifiable(topics);

  /// The topics, in the order they were declared.
  ///
  /// Names are unique, which the declaration enforces as it goes rather
  /// than reporting here.
  final List<EventTopicData<Event>> topics;

  /// States what is wrong with this declaration.
  @override
  void validate(ValidationScope scope) {
    if (topics.isEmpty) {
      scope.fail(
        'must declare at least one topic',
        property: 'topics',
        code: EventViolationCodes.noTopics,
      );
    }
  }
}
