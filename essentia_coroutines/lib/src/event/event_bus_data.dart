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

import 'package:essentia_core/essentia_core.dart';
import 'package:essentia_coroutines/src/event/event.dart';
import 'package:essentia_coroutines/src/event/event_topic_data.dart';
import 'package:essentia_coroutines/src/event/event_violation_codes.dart';
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
