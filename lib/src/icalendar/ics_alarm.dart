/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/icalendar/ics_alarm_action.dart';
import 'package:essentia/src/icalendar/ics_attendee.dart';
import 'package:essentia/src/icalendar/ics_property.dart';
import 'package:essentia/src/icalendar/ics_trigger.dart';
import 'package:essentia/src/time/date_time_period.dart';
import 'package:meta/meta.dart';

/// A reminder of an entry, the `VALARM` of RFC 5545.
@immutable
final class IcsAlarm {
  /// The alarm that does [action] when [trigger] says.
  IcsAlarm({
    required this.action,
    required this.trigger,
    this.description,
    this.summary,
    this.repeat,
    this.repeatEvery,
    List<IcsAttendee> attendees = const <IcsAttendee>[],
    List<IcsProperty> properties = const <IcsProperty>[],
  }) : attendees = List<IcsAttendee>.unmodifiable(attendees),
       properties = List<IcsProperty>.unmodifiable(properties);

  /// What the alarm does.
  final IcsAlarmAction action;

  /// When the alarm goes off.
  final IcsTrigger trigger;

  /// The text the alarm shows or sends.
  final String? description;

  /// The subject of an email alarm.
  final String? summary;

  /// How often the alarm repeats after the first time.
  final int? repeat;

  /// How long it waits between repeats.
  final DateTimePeriod? repeatEvery;

  /// Who an email alarm goes to.
  final List<IcsAttendee> attendees;

  /// The properties this type does not read, kept as written.
  final List<IcsProperty> properties;

  /// Whether [other] is the same alarm.
  @override
  bool operator ==(Object other) =>
      other is IcsAlarm && other.toString() == toString();

  /// A hash of the alarm.
  @override
  int get hashCode => toString().hashCode;

  /// Describes the alarm.
  @override
  String toString() =>
      'IcsAlarm($action, $trigger, $description, $summary, $repeat, '
      '$repeatEvery, $attendees, $properties)';
}
