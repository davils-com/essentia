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

/// Recurrence as RFC 5545 describes it: rules and sets that expand
/// repetitions across time zones.
///
/// ```dart
/// final berlin = TimeZone.of('Europe/Berlin');
/// final standup = RecurrenceSet(
///   ZonedAnchor(LocalDateTime.of(2026, 10, 5, 9, 30), berlin),
///   rules: <RecurrenceRule>[
///     RecurrenceRule.parse('FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR'),
///   ],
/// );
/// ```
library;

export 'src/recurrence/recurrence_anchor.dart';
export 'src/recurrence/recurrence_frequency.dart';
export 'src/recurrence/recurrence_occurrence.dart';
export 'src/recurrence/recurrence_rule.dart';
export 'src/recurrence/recurrence_rule_builder.dart';
export 'src/recurrence/recurrence_rule_dsl.dart';
export 'src/recurrence/recurrence_set.dart';
export 'src/recurrence/recurrence_until.dart';
export 'src/recurrence/recurrence_violation_codes.dart';
export 'src/recurrence/recurrence_weekday.dart';
