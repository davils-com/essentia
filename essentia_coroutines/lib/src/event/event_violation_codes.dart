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

/// The stable identifiers of everything a bus declaration can get wrong.
///
/// A message may be reworded at any time; these do not change. Match on
/// them to react to a particular kind of problem, or to key a translation
/// by.
///
/// Not everything wrong with a declaration appears here. A blank or
/// duplicate topic name is a mistake in the source rather than a
/// configuration that could have come from somewhere else, so it is refused
/// on the spot rather than collected into a report.
abstract final class EventViolationCodes {
  /// A bus was declared without a single topic.
  static const noTopics = ViolationCode('essentia.event.no-topics');

  /// A topic asked to replay a negative number of events to new
  /// subscribers.
  static const invalidReplay = ViolationCode('essentia.event.invalid-replay');

  /// A topic's buffer capacity was negative, or zero where the overflow
  /// policy needs room.
  static const invalidBuffer = ViolationCode('essentia.event.invalid-buffer');

  /// A topic asked for fewer than one partition.
  static const invalidPartitions = ViolationCode(
    'essentia.event.invalid-partitions',
  );

  /// A topic demanded a key on every publication but has only one partition
  /// to order by it.
  ///
  /// This is a warning: the bus starts, and the demand is simply pointless,
  /// because a single partition already orders everything totally.
  static const keyWithoutPartitions = ViolationCode(
    'essentia.event.key-without-partitions',
  );

  /// A bus-wide default was set, or an interceptor added, after a topic had
  /// been declared.
  ///
  /// A warning: the declaration is valid, but a default reaches only the
  /// topics declared after it, so the ones above keep what was in force
  /// where they were written. The usual symptom is a listener meant for
  /// every topic that is told about none of the early ones.
  static const lateDefault = ViolationCode('essentia.event.late-default');
}
