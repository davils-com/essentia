/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/icalendar/ics_alarm.dart';
import 'package:essentia/src/icalendar/ics_attendee.dart';
import 'package:essentia/src/icalendar/ics_classification.dart';
import 'package:essentia/src/icalendar/ics_component.dart';
import 'package:essentia/src/icalendar/ics_date_time.dart';
import 'package:essentia/src/icalendar/ics_event_status.dart';
import 'package:essentia/src/icalendar/ics_organizer.dart';
import 'package:essentia/src/icalendar/ics_property.dart';
import 'package:essentia/src/icalendar/ics_todo_status.dart';
import 'package:essentia/src/icalendar/ics_transparency.dart';
import 'package:essentia/src/icalendar/internal/ics_equality.dart';
import 'package:essentia/src/recurrence/recurrence_anchor.dart';
import 'package:essentia/src/recurrence/recurrence_rule.dart';
import 'package:essentia/src/recurrence/recurrence_set.dart';
import 'package:essentia/src/time/date_time_period.dart';
import 'package:essentia/src/time/instant.dart';
import 'package:essentia/src/time/local_date.dart';
import 'package:essentia/src/time/local_date_time.dart';
import 'package:essentia/src/time/time_zone.dart';
import 'package:meta/meta.dart';

/// What an iCalendar file plans: an [IcsEvent] or an [IcsTodo], with the
/// properties both share.
///
/// Every property this library does not read is kept in [properties], and
/// every nested component it does not read in [components], so a file
/// written back loses nothing.
@immutable
sealed class IcsEntry {
  /// Creates the entry of the shared parts.
  IcsEntry({
    required this.uid,
    this.stamp,
    this.start,
    this.duration,
    this.summary,
    this.description,
    this.location,
    this.classification,
    List<String> categories = const <String>[],
    this.organizer,
    List<IcsAttendee> attendees = const <IcsAttendee>[],
    List<IcsAlarm> alarms = const <IcsAlarm>[],
    List<RecurrenceRule> rules = const <RecurrenceRule>[],
    List<IcsDateTime> dates = const <IcsDateTime>[],
    List<IcsDateTime> exceptions = const <IcsDateTime>[],
    this.recurrenceId,
    this.thisAndFuture = false,
    this.sequence,
    this.created,
    this.lastModified,
    this.url,
    this.priority,
    this.geo,
    this.color,
    List<IcsProperty> properties = const <IcsProperty>[],
    List<IcsComponent> components = const <IcsComponent>[],
  }) : categories = List<String>.unmodifiable(categories),
       attendees = List<IcsAttendee>.unmodifiable(attendees),
       alarms = List<IcsAlarm>.unmodifiable(alarms),
       rules = List<RecurrenceRule>.unmodifiable(rules),
       dates = List<IcsDateTime>.unmodifiable(dates),
       exceptions = List<IcsDateTime>.unmodifiable(exceptions),
       properties = List<IcsProperty>.unmodifiable(properties),
       components = List<IcsComponent>.unmodifiable(components);

  /// The identifier that stays the same across every version, `UID`.
  final String uid;

  /// When this version was written, `DTSTAMP`.
  final Instant? stamp;

  /// When it starts, `DTSTART`.
  final IcsDateTime? start;

  /// How long it lasts, `DURATION`.
  final DateTimePeriod? duration;

  /// The title, `SUMMARY`.
  final String? summary;

  /// The longer text, `DESCRIPTION`.
  final String? description;

  /// Where, `LOCATION`.
  final String? location;

  /// Who may see it, `CLASS`.
  final IcsClassification? classification;

  /// The categories, `CATEGORIES`.
  final List<String> categories;

  /// Who organises it, `ORGANIZER`.
  final IcsOrganizer? organizer;

  /// Who is invited, `ATTENDEE`.
  final List<IcsAttendee> attendees;

  /// The reminders, `VALARM`.
  final List<IcsAlarm> alarms;

  /// The recurrence rules, `RRULE`.
  final List<RecurrenceRule> rules;

  /// The extra repetitions, `RDATE`.
  final List<IcsDateTime> dates;

  /// The repetitions left out, `EXDATE`.
  final List<IcsDateTime> exceptions;

  /// The repetition this entry replaces, `RECURRENCE-ID`.
  final IcsDateTime? recurrenceId;

  /// Whether the replacement applies to that repetition and every later
  /// one, `RANGE=THISANDFUTURE`.
  final bool thisAndFuture;

  /// The revision, `SEQUENCE`.
  final int? sequence;

  /// When it was made, `CREATED`.
  final Instant? created;

  /// When it was last changed, `LAST-MODIFIED`.
  final Instant? lastModified;

  /// A link, `URL`.
  final String? url;

  /// The priority from 1, the highest, to 9, or 0 for none, `PRIORITY`.
  final int? priority;

  /// The latitude and longitude, `GEO`.
  final (double, double)? geo;

  /// The colour name of RFC 7986, `COLOR`.
  final String? color;

  /// The properties this library does not read, as written.
  final List<IcsProperty> properties;

  /// The nested components this library does not read, as written.
  final List<IcsComponent> components;

  /// The repetitions of the entry, read in the zones [zoneOf] finds, or
  /// `null` when it has no start.
  ///
  /// Extra dates and exceptions of another zone or in UTC are read on the
  /// clock of the start.
  RecurrenceSet? recurrenceSet(TimeZone? Function(String id) zoneOf) {
    final IcsDateTime? first = start;
    if (first == null) {
      return null;
    }
    final RecurrenceAnchor anchor = switch (first) {
      IcsDate(:final LocalDate date) => DateAnchor(date),
      IcsFloatingDateTime(:final LocalDateTime local) => FloatingAnchor(local),
      IcsUtcDateTime(:final Instant instant) => ZonedAnchor.at(
        instant,
        TimeZone.utc,
      ),
      IcsZonedDateTime(:final LocalDateTime local, :final String zoneId) =>
        ZonedAnchor(local, zoneOf(zoneId) ?? TimeZone.utc),
    };
    LocalDateTime localOf(IcsDateTime value) {
      final TimeZone? zone = anchor.zone;
      if (zone == null || value is IcsDate || value is IcsFloatingDateTime) {
        return value.local;
      }
      return zone.toLocalDateTime(value.toInstant(zoneOf));
    }

    return RecurrenceSet(
      anchor,
      rules: rules,
      dates: dates.map(localOf).toList(),
      exceptions: exceptions.map(localOf).toList(),
    );
  }

  /// The values that make the entry, in a fixed order, for equality.
  @protected
  List<Object?> get values => <Object?>[
    uid,
    stamp,
    start,
    duration,
    summary,
    description,
    location,
    classification,
    categories,
    organizer,
    attendees,
    alarms,
    rules,
    dates,
    exceptions,
    recurrenceId,
    thisAndFuture,
    sequence,
    created,
    lastModified,
    url,
    priority,
    geo,
    color,
    properties,
    components,
  ];

  /// Whether [other] is an entry of the same kind and values.
  @override
  bool operator ==(Object other) =>
      other is IcsEntry &&
      other.runtimeType == runtimeType &&
      sameIcsValues(other.values, values);

  /// A hash of the entry.
  @override
  int get hashCode => hashIcsValues(values);
}

/// Something that happens at a time, the `VEVENT` of RFC 5545.
final class IcsEvent extends IcsEntry {
  /// The event of [uid].
  IcsEvent({
    required super.uid,
    super.stamp,
    super.start,
    this.end,
    super.duration,
    super.summary,
    super.description,
    super.location,
    this.status,
    this.transparency,
    super.classification,
    super.categories,
    super.organizer,
    super.attendees,
    super.alarms,
    super.rules,
    super.dates,
    super.exceptions,
    super.recurrenceId,
    super.thisAndFuture,
    super.sequence,
    super.created,
    super.lastModified,
    super.url,
    super.priority,
    super.geo,
    super.color,
    super.properties,
    super.components,
  });

  /// When it ends, `DTEND`, exclusive.
  final IcsDateTime? end;

  /// Its state, `STATUS`.
  final IcsEventStatus? status;

  /// Whether it blocks time, `TRANSP`.
  final IcsTransparency? transparency;

  /// The values that make the event, for equality.
  @override
  @protected
  List<Object?> get values => <Object?>[
    ...super.values,
    end,
    status,
    transparency,
  ];

  /// Describes the event briefly.
  @override
  String toString() => 'IcsEvent($uid, $summary, $start)';
}

/// Something to be done, the `VTODO` of RFC 5545.
final class IcsTodo extends IcsEntry {
  /// The to-do of [uid].
  IcsTodo({
    required super.uid,
    super.stamp,
    super.start,
    this.due,
    super.duration,
    this.completed,
    this.percentComplete,
    super.summary,
    super.description,
    super.location,
    this.status,
    super.classification,
    super.categories,
    super.organizer,
    super.attendees,
    super.alarms,
    super.rules,
    super.dates,
    super.exceptions,
    super.recurrenceId,
    super.thisAndFuture,
    super.sequence,
    super.created,
    super.lastModified,
    super.url,
    super.priority,
    super.geo,
    super.color,
    super.properties,
    super.components,
  });

  /// When it is due, `DUE`.
  final IcsDateTime? due;

  /// When it was done, `COMPLETED`.
  final Instant? completed;

  /// How much of it is done, from 0 to 100, `PERCENT-COMPLETE`.
  final int? percentComplete;

  /// Its state, `STATUS`.
  final IcsTodoStatus? status;

  /// The values that make the to-do, for equality.
  @override
  @protected
  List<Object?> get values => <Object?>[
    ...super.values,
    due,
    completed,
    percentComplete,
    status,
  ];

  /// Describes the to-do briefly.
  @override
  String toString() => 'IcsTodo($uid, $summary, $due)';
}
