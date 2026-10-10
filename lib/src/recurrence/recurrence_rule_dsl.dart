/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/recurrence/recurrence_rule.dart';
import 'package:essentia/src/recurrence/recurrence_rule_builder.dart';
import 'package:essentia/src/scope/scope_functions.dart';

/// Builds a recurrence rule in a configuration block, the Kotlin way.
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
