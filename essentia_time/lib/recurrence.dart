/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
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
