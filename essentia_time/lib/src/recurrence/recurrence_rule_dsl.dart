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
import 'package:essentia_time/src/recurrence/recurrence_rule.dart';
import 'package:essentia_time/src/recurrence/recurrence_rule_builder.dart';

/// Builds a recurrence rule in a configuration block.
///
/// ```dart
/// final RecurrenceRule everyOtherWeek = recurrenceRule((it) {
///   it.frequency = RecurrenceFrequency.weekly;
///   it.interval = 2;
///   it.weekday(DayOfWeek.monday);
///   it.weekday(DayOfWeek.wednesday);
/// });
/// ```
///
/// Returns the rule.
///
/// Throws a `ValidationException` that lists every part that breaks
/// RFC 5545.
RecurrenceRule recurrenceRule(void Function(RecurrenceRuleBuilder it) block) =>
    RecurrenceRuleBuilder().apply(block).build();
