/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// Calendars as RFC 5545 describes them: recurrence rules and sets that
/// expand repetitions across time zones, and the iCalendar format.
///
/// ```dart
/// final berlin = TimeZone.of('Europe/Berlin');
/// final standup = RecurrenceSet(
///   ZonedAnchor(LocalDateTime.of(2026, 10, 5, 9, 30), berlin),
///   rules: <RecurrenceRule>[
///     RecurrenceRule.parse('FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR'),
///   ],
/// );
/// final List<RecurrenceOccurrence> thisWeek = standup.occurrencesBetween(
///   LocalDateTime.of(2026, 10, 5, 0, 0),
///   LocalDateTime.of(2026, 10, 12, 0, 0),
/// );
/// ```
library;

export 'src/icalendar/ics_alarm.dart';
export 'src/icalendar/ics_alarm_action.dart';
export 'src/icalendar/ics_attendee.dart';
export 'src/icalendar/ics_calendar.dart';
export 'src/icalendar/ics_classification.dart';
export 'src/icalendar/ics_codec.dart';
export 'src/icalendar/ics_component.dart';
export 'src/icalendar/ics_date_time.dart';
export 'src/icalendar/ics_entry.dart';
export 'src/icalendar/ics_event_status.dart';
export 'src/icalendar/ics_organizer.dart';
export 'src/icalendar/ics_parse_exception.dart';
export 'src/icalendar/ics_parse_options.dart';
export 'src/icalendar/ics_parse_result.dart';
export 'src/icalendar/ics_participation.dart';
export 'src/icalendar/ics_property.dart';
export 'src/icalendar/ics_reader.dart';
export 'src/icalendar/ics_role.dart';
export 'src/icalendar/ics_text.dart';
export 'src/icalendar/ics_time_zone.dart';
export 'src/icalendar/ics_time_zone_observance.dart';
export 'src/icalendar/ics_todo_status.dart';
export 'src/icalendar/ics_transparency.dart';
export 'src/icalendar/ics_trigger.dart';
export 'src/icalendar/ics_user_type.dart';
export 'src/icalendar/ics_values.dart';
export 'src/icalendar/ics_writer.dart';
export 'src/icalendar/ics_zone_resolver.dart';
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
