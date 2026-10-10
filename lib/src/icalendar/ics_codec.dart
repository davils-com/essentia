/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/icalendar/ics_alarm.dart';
import 'package:essentia/src/icalendar/ics_alarm_action.dart';
import 'package:essentia/src/icalendar/ics_attendee.dart';
import 'package:essentia/src/icalendar/ics_calendar.dart';
import 'package:essentia/src/icalendar/ics_classification.dart';
import 'package:essentia/src/icalendar/ics_component.dart';
import 'package:essentia/src/icalendar/ics_date_time.dart';
import 'package:essentia/src/icalendar/ics_entry.dart';
import 'package:essentia/src/icalendar/ics_event_status.dart';
import 'package:essentia/src/icalendar/ics_organizer.dart';
import 'package:essentia/src/icalendar/ics_parse_exception.dart';
import 'package:essentia/src/icalendar/ics_parse_options.dart';
import 'package:essentia/src/icalendar/ics_parse_result.dart';
import 'package:essentia/src/icalendar/ics_participation.dart';
import 'package:essentia/src/icalendar/ics_property.dart';
import 'package:essentia/src/icalendar/ics_reader.dart';
import 'package:essentia/src/icalendar/ics_role.dart';
import 'package:essentia/src/icalendar/ics_text.dart';
import 'package:essentia/src/icalendar/ics_time_zone.dart';
import 'package:essentia/src/icalendar/ics_time_zone_observance.dart';
import 'package:essentia/src/icalendar/ics_todo_status.dart';
import 'package:essentia/src/icalendar/ics_transparency.dart';
import 'package:essentia/src/icalendar/ics_trigger.dart';
import 'package:essentia/src/icalendar/ics_user_type.dart';
import 'package:essentia/src/icalendar/ics_values.dart';
import 'package:essentia/src/icalendar/ics_writer.dart';
import 'package:essentia/src/recurrence/recurrence_rule.dart';
import 'package:essentia/src/time/clock.dart';
import 'package:essentia/src/time/date_time_period.dart';
import 'package:essentia/src/time/instant.dart';
import 'package:essentia/src/time/local_date_time.dart';
import 'package:essentia/src/time/time_zone.dart';
import 'package:essentia/src/time/utc_offset.dart';
import 'package:meta/meta.dart';

/// The properties of an entry this codec reads into fields; every other
/// one is kept as written.
const _entryProperties = <String>{
  'UID',
  'DTSTAMP',
  'DTSTART',
  'DTEND',
  'DUE',
  'DURATION',
  'COMPLETED',
  'PERCENT-COMPLETE',
  'SUMMARY',
  'DESCRIPTION',
  'LOCATION',
  'STATUS',
  'TRANSP',
  'CLASS',
  'CATEGORIES',
  'ORGANIZER',
  'ATTENDEE',
  'RRULE',
  'RDATE',
  'EXDATE',
  'RECURRENCE-ID',
  'SEQUENCE',
  'CREATED',
  'LAST-MODIFIED',
  'URL',
  'PRIORITY',
  'GEO',
  'COLOR',
};

/// Reads and writes iCalendar files, RFC 5545: `VCALENDAR`, `VEVENT`,
/// `VTODO`, `VALARM` and `VTIMEZONE` become typed values, everything else
/// is kept as written, so a file read and written back loses nothing.
///
/// ```dart
/// const codec = IcsCodec();
/// final IcsCalendar calendar = codec.decode(text).calendar;
/// final String written = codec.encode(calendar);
/// ```
///
/// A strict read refuses a file with an [IcsParseException] that lists
/// every problem; a lenient one reads past them and reports warnings. A
/// write describes every zone of the time zone database its entries name
/// in a `VTIMEZONE`, so any reader finds their offsets.
@immutable
final class IcsCodec {
  /// The codec that names itself [productId] and stamps entries without a
  /// stamp with the time of [clock].
  const IcsCodec({
    this.productId = '-//Davils//Essentia//EN',
    this.clock = Clock.system,
  });

  /// The `PRODID` written when a calendar has none.
  final String productId;

  /// The clock of the `DTSTAMP` written when an entry has none.
  final Clock clock;

  /// Reads the calendars of [text].
  ///
  /// Throws an [IcsParseException] listing every problem, unless the
  /// [options] are lenient.
  IcsParseResult decode(
    String text, {
    IcsParseOptions options = const IcsParseOptions(),
  }) {
    final problems = <String>[];
    final calendars = <IcsCalendar>[];
    for (final IcsComponent root in readIcs(text, problems)) {
      if (root.name != 'VCALENDAR') {
        problems.add('${root.name} lies outside a VCALENDAR');
        continue;
      }
      calendars.add(_calendar(root, problems, lenient: options.lenient));
    }
    if (calendars.isEmpty) {
      problems.add('the text holds no VCALENDAR');
    }
    if (!options.lenient && problems.isNotEmpty) {
      throw IcsParseException(problems);
    }
    return IcsParseResult(calendars, problems);
  }

  /// Writes [calendar] as iCalendar text.
  String encode(IcsCalendar calendar) => writeIcs(toComponent(calendar));

  /// [calendar] as a `VCALENDAR` component, with a `VTIMEZONE` for every
  /// zone of the time zone database its entries name and it does not
  /// describe itself.
  IcsComponent toComponent(IcsCalendar calendar) {
    final String? name = calendar.name;
    return IcsComponent(
      'VCALENDAR',
      properties: <IcsProperty>[
        IcsProperty('VERSION', '2.0'),
        IcsProperty('PRODID', calendar.productId ?? productId),
        if (calendar.scale != null) IcsProperty('CALSCALE', calendar.scale!),
        if (calendar.method != null) IcsProperty('METHOD', calendar.method!),
        if (name != null) IcsProperty('NAME', escapeIcsText(name)),
        if (name != null) IcsProperty('X-WR-CALNAME', escapeIcsText(name)),
        ...calendar.properties,
      ],
      components: <IcsComponent>[
        for (final IcsTimeZone zone in <IcsTimeZone>[
          ...calendar.timeZones,
          ..._missingZones(calendar),
        ])
          _timeZoneComponent(zone),
        for (final IcsEvent event in calendar.events) _entryComponent(event),
        for (final IcsTodo todo in calendar.todos) _entryComponent(todo),
        ...calendar.components,
      ],
    );
  }

  /// The zones of the database the entries of [calendar] name without a
  /// description of their own, each over the span its entries use.
  List<IcsTimeZone> _missingZones(IcsCalendar calendar) {
    final described = <String>{
      for (final IcsTimeZone zone in calendar.timeZones) zone.id,
    };
    final spans = <String, (Instant, Instant)>{};
    for (final IcsEntry entry in calendar.entries) {
      final values = <IcsDateTime?>[
        entry.start,
        entry.recurrenceId,
        ...entry.dates,
        ...entry.exceptions,
        if (entry is IcsEvent) entry.end,
        if (entry is IcsTodo) entry.due,
      ];
      for (final value in values) {
        if (value is! IcsZonedDateTime || described.contains(value.zoneId)) {
          continue;
        }
        final TimeZone? zone = TimeZone.ofOrNull(value.zoneId);
        if (zone == null) {
          continue;
        }
        final Instant at = zone.toInstant(value.local);
        final (Instant, Instant)? span = spans[value.zoneId];
        spans[value.zoneId] = span == null
            ? (at, at)
            : (
                at.isBefore(span.$1) ? at : span.$1,
                at.isAfter(span.$2) ? at : span.$2,
              );
      }
    }
    return <IcsTimeZone>[
      for (final MapEntry<String, (Instant, Instant)> span in spans.entries)
        IcsTimeZone.fromTimeZone(
          TimeZone.of(span.key),
          from: span.value.$1,
          until: span.value.$2,
        ),
    ];
  }

  /// [zone] as a `VTIMEZONE` component.
  static IcsComponent _timeZoneComponent(IcsTimeZone zone) => IcsComponent(
    'VTIMEZONE',
    properties: <IcsProperty>[IcsProperty('TZID', zone.id), ...zone.properties],
    components: <IcsComponent>[
      for (final IcsTimeZoneObservance observance in zone.observances)
        IcsComponent(
          observance.daylight ? 'DAYLIGHT' : 'STANDARD',
          properties: <IcsProperty>[
            icsDateTimeProperty(
              'DTSTART',
              IcsFloatingDateTime(observance.start),
            ),
            IcsProperty('TZOFFSETFROM', formatIcsOffset(observance.offsetFrom)),
            IcsProperty('TZOFFSETTO', formatIcsOffset(observance.offsetTo)),
            for (final RecurrenceRule rule in observance.rules)
              IcsProperty('RRULE', rule.toString()),
            if (observance.dates.isNotEmpty)
              icsDateTimeListProperty('RDATE', <IcsDateTime>[
                for (final LocalDateTime date in observance.dates)
                  IcsFloatingDateTime(date),
              ]),
            for (final String name in observance.names)
              IcsProperty('TZNAME', escapeIcsText(name)),
            ...observance.properties,
          ],
        ),
    ],
  );

  /// [entry] as a `VEVENT` or `VTODO` component.
  IcsComponent _entryComponent(IcsEntry entry) {
    final IcsDateTime? start = entry.start;
    final DateTimePeriod? duration = entry.duration;
    final IcsDateTime? recurrenceId = entry.recurrenceId;
    final (double, double)? geo = entry.geo;
    final IcsOrganizer? organizer = entry.organizer;
    return IcsComponent(
      entry is IcsTodo ? 'VTODO' : 'VEVENT',
      properties: <IcsProperty>[
        IcsProperty('UID', entry.uid),
        IcsProperty(
          'DTSTAMP',
          formatIcsDateTime(IcsUtcDateTime(entry.stamp ?? clock.now())),
        ),
        if (start != null) icsDateTimeProperty('DTSTART', start),
        ..._specific(entry),
        if (duration != null)
          IcsProperty('DURATION', formatIcsDuration(duration)),
        ..._text('SUMMARY', entry.summary),
        ..._text('DESCRIPTION', entry.description),
        ..._text('LOCATION', entry.location),
        if (entry.classification != null)
          IcsProperty('CLASS', entry.classification!.value),
        if (entry.categories.isNotEmpty)
          IcsProperty(
            'CATEGORIES',
            entry.categories.map(escapeIcsText).join(','),
          ),
        if (organizer != null)
          IcsProperty(
            'ORGANIZER',
            organizer.address,
            parameters: <String, List<String>>{
              if (organizer.name != null) 'CN': <String>[organizer.name!],
              if (organizer.sentBy != null)
                'SENT-BY': <String>[organizer.sentBy!],
            },
          ),
        for (final IcsAttendee attendee in entry.attendees)
          _attendeeProperty(attendee),
        for (final RecurrenceRule rule in entry.rules)
          IcsProperty('RRULE', rule.toString()),
        ..._dateLists('RDATE', entry.dates),
        ..._dateLists('EXDATE', entry.exceptions),
        if (recurrenceId != null)
          _withRange(
            icsDateTimeProperty('RECURRENCE-ID', recurrenceId),
            thisAndFuture: entry.thisAndFuture,
          ),
        if (entry.sequence != null)
          IcsProperty('SEQUENCE', '${entry.sequence}'),
        if (entry.created != null)
          IcsProperty(
            'CREATED',
            formatIcsDateTime(IcsUtcDateTime(entry.created!)),
          ),
        if (entry.lastModified != null)
          IcsProperty(
            'LAST-MODIFIED',
            formatIcsDateTime(IcsUtcDateTime(entry.lastModified!)),
          ),
        if (entry.url != null) IcsProperty('URL', entry.url!),
        if (entry.priority != null)
          IcsProperty('PRIORITY', '${entry.priority}'),
        if (geo != null) IcsProperty('GEO', '${geo.$1};${geo.$2}'),
        if (entry.color != null) IcsProperty('COLOR', entry.color!),
        ...entry.properties,
      ],
      components: <IcsComponent>[
        for (final IcsAlarm alarm in entry.alarms) _alarmComponent(alarm),
        ...entry.components,
      ],
    );
  }

  /// The properties only an event or only a to-do has.
  List<IcsProperty> _specific(IcsEntry entry) => switch (entry) {
    IcsEvent(:final end, :final status, :final transparency) => <IcsProperty>[
      if (end != null) icsDateTimeProperty('DTEND', end),
      if (status != null) IcsProperty('STATUS', status.value),
      if (transparency != null) IcsProperty('TRANSP', transparency.value),
    ],
    IcsTodo(
      :final due,
      :final completed,
      :final percentComplete,
      :final status,
    ) =>
      <IcsProperty>[
        if (due != null) icsDateTimeProperty('DUE', due),
        if (completed != null)
          IcsProperty(
            'COMPLETED',
            formatIcsDateTime(IcsUtcDateTime(completed)),
          ),
        if (percentComplete != null)
          IcsProperty('PERCENT-COMPLETE', '$percentComplete'),
        if (status != null) IcsProperty('STATUS', status.value),
      ],
  };

  /// The text property [name] of [value], or none.
  static List<IcsProperty> _text(String name, String? value) => <IcsProperty>[
    if (value != null) IcsProperty(name, escapeIcsText(value)),
  ];

  /// One property [name] per kind and zone of [values].
  static List<IcsProperty> _dateLists(String name, List<IcsDateTime> values) {
    final groups = <String, List<IcsDateTime>>{};
    for (final value in values) {
      final String key = switch (value) {
        IcsDate() => 'date',
        IcsUtcDateTime() => 'utc',
        IcsFloatingDateTime() => 'floating',
        IcsZonedDateTime(:final String zoneId) => 'zone:$zoneId',
      };
      groups.putIfAbsent(key, () => <IcsDateTime>[]).add(value);
    }
    return <IcsProperty>[
      for (final List<IcsDateTime> group in groups.values)
        icsDateTimeListProperty(name, group),
    ];
  }

  /// [property] with `RANGE=THISANDFUTURE` when [thisAndFuture].
  static IcsProperty _withRange(
    IcsProperty property, {
    required bool thisAndFuture,
  }) {
    if (!thisAndFuture) {
      return property;
    }
    return IcsProperty(
      property.name,
      property.value,
      parameters: <String, List<String>>{
        ...property.parameters,
        'RANGE': const <String>['THISANDFUTURE'],
      },
    );
  }

  /// [attendee] as an `ATTENDEE` property.
  static IcsProperty _attendeeProperty(IcsAttendee attendee) => IcsProperty(
    'ATTENDEE',
    attendee.address,
    parameters: <String, List<String>>{
      if (attendee.name != null) 'CN': <String>[attendee.name!],
      if (attendee.role != null) 'ROLE': <String>[attendee.role!.value],
      if (attendee.participation != null)
        'PARTSTAT': <String>[attendee.participation!.value],
      if (attendee.userType != null)
        'CUTYPE': <String>[attendee.userType!.value],
      if (attendee.rsvp) 'RSVP': const <String>['TRUE'],
      if (attendee.delegatedTo.isNotEmpty) 'DELEGATED-TO': attendee.delegatedTo,
      if (attendee.delegatedFrom.isNotEmpty)
        'DELEGATED-FROM': attendee.delegatedFrom,
      if (attendee.sentBy != null) 'SENT-BY': <String>[attendee.sentBy!],
      if (attendee.members.isNotEmpty) 'MEMBER': attendee.members,
    },
  );

  /// [alarm] as a `VALARM` component.
  static IcsComponent _alarmComponent(IcsAlarm alarm) {
    final IcsTrigger trigger = alarm.trigger;
    final DateTimePeriod? every = alarm.repeatEvery;
    return IcsComponent(
      'VALARM',
      properties: <IcsProperty>[
        IcsProperty('ACTION', alarm.action.value),
        switch (trigger) {
          IcsRelativeTrigger(:final offset, :final fromEnd) => IcsProperty(
            'TRIGGER',
            formatIcsDuration(offset),
            parameters: <String, List<String>>{
              if (fromEnd) 'RELATED': const <String>['END'],
            },
          ),
          IcsAbsoluteTrigger(:final instant) => IcsProperty(
            'TRIGGER',
            formatIcsDateTime(IcsUtcDateTime(instant)),
            parameters: const <String, List<String>>{
              'VALUE': <String>['DATE-TIME'],
            },
          ),
        },
        ..._text('DESCRIPTION', alarm.description),
        ..._text('SUMMARY', alarm.summary),
        if (alarm.repeat != null) IcsProperty('REPEAT', '${alarm.repeat}'),
        if (every != null) IcsProperty('DURATION', formatIcsDuration(every)),
        for (final IcsAttendee attendee in alarm.attendees)
          _attendeeProperty(attendee),
        ...alarm.properties,
      ],
    );
  }
}

/// Reads the calendar [component], adding what it cannot read to
/// [problems].
IcsCalendar _calendar(
  IcsComponent component,
  List<String> problems, {
  required bool lenient,
}) {
  final String? floatingZone = lenient
      ? component.property('X-WR-TIMEZONE')?.value
      : null;
  final events = <IcsEvent>[];
  final todos = <IcsTodo>[];
  final zones = <IcsTimeZone>[];
  final others = <IcsComponent>[];
  for (final IcsComponent child in component.components) {
    switch (child.name) {
      case 'VEVENT' || 'VTODO':
        final IcsEntry entry = _entry(
          child,
          problems,
          index: events.length + todos.length,
          floatingZone: floatingZone,
        );
        if (entry is IcsEvent) {
          events.add(entry);
        }
        if (entry is IcsTodo) {
          todos.add(entry);
        }
      case 'VTIMEZONE':
        final IcsTimeZone? zone = _timeZone(child, problems);
        if (zone != null) {
          zones.add(zone);
        }
      case String():
        others.add(child);
    }
  }
  final IcsProperty? name =
      component.property('NAME') ?? component.property('X-WR-CALNAME');
  return IcsCalendar(
    productId: component.property('PRODID')?.value,
    method: component.property('METHOD')?.value,
    scale: component.property('CALSCALE')?.value,
    name: name == null ? null : unescapeIcsText(name.value),
    events: events,
    todos: todos,
    timeZones: zones,
    properties: <IcsProperty>[
      for (final IcsProperty property in component.properties)
        if (!const <String>{
          'VERSION',
          'PRODID',
          'METHOD',
          'CALSCALE',
          'NAME',
          'X-WR-CALNAME',
        }.contains(property.name))
          property,
    ],
    components: others,
  );
}

/// Reads the time zone [component], or `null` with a problem when it has
/// no identifier.
IcsTimeZone? _timeZone(IcsComponent component, List<String> problems) {
  final String? id = component.property('TZID')?.value;
  if (id == null) {
    problems.add('VTIMEZONE: no TZID');
    return null;
  }
  final observances = <IcsTimeZoneObservance>[];
  for (final IcsComponent part in component.components) {
    if (part.name != 'STANDARD' && part.name != 'DAYLIGHT') {
      continue;
    }
    final where = 'VTIMEZONE $id ${part.name}';
    final IcsDateTime? start = _value(
      part,
      'DTSTART',
      (it) => parseIcsDateTime(it.value, it),
      where,
      problems,
    );
    final UtcOffset? from = _value(
      part,
      'TZOFFSETFROM',
      (it) => parseIcsOffset(it.value),
      where,
      problems,
    );
    final UtcOffset? to = _value(
      part,
      'TZOFFSETTO',
      (it) => parseIcsOffset(it.value),
      where,
      problems,
    );
    if (start == null || from == null || to == null) {
      problems.add('$where: needs DTSTART, TZOFFSETFROM and TZOFFSETTO');
      continue;
    }
    observances.add(
      IcsTimeZoneObservance(
        daylight: part.name == 'DAYLIGHT',
        start: start.local,
        offsetFrom: from,
        offsetTo: to,
        rules: _rules(part, where, problems),
        dates: <LocalDateTime>[
          for (final IcsDateTime date in _dates(part, 'RDATE', where, problems))
            date.local,
        ],
        names: <String>[
          for (final IcsProperty name in part.all('TZNAME'))
            unescapeIcsText(name.value),
        ],
        properties: <IcsProperty>[
          for (final IcsProperty property in part.properties)
            if (!const <String>{
              'DTSTART',
              'TZOFFSETFROM',
              'TZOFFSETTO',
              'RRULE',
              'RDATE',
              'TZNAME',
            }.contains(property.name))
              property,
        ],
      ),
    );
  }
  if (observances.isEmpty) {
    problems.add('VTIMEZONE $id: no usable STANDARD or DAYLIGHT');
    return null;
  }
  return IcsTimeZone(
    id: id,
    observances: observances,
    properties: <IcsProperty>[
      for (final IcsProperty property in component.properties)
        if (property.name != 'TZID') property,
    ],
  );
}

/// Reads the entry [component], the [index]th of its calendar; the times
/// that float are read in [floatingZone] when it is given.
IcsEntry _entry(
  IcsComponent component,
  List<String> problems, {
  required int index,
  required String? floatingZone,
}) {
  final String? given = component.property('UID')?.value;
  final where = '${component.name} ${given ?? '#${index + 1}'}';
  if (given == null) {
    problems.add('$where: no UID');
  }
  final String uid = given ?? 'missing-uid-${index + 1}';
  IcsDateTime? date(String name) {
    final IcsDateTime? value = _value(
      component,
      name,
      (it) => parseIcsDateTime(it.value, it),
      where,
      problems,
    );
    return _zoned(value, floatingZone);
  }

  Instant? instant(String name) => _instantOf(date(name));
  String? text(String name) {
    final IcsProperty? property = component.property(name);
    return property == null ? null : unescapeIcsText(property.value);
  }

  int? number(String name) => _value(
    component,
    name,
    (it) =>
        int.tryParse(it.value.trim()) ??
        (throw FormatException('Not a number', it.value)),
    where,
    problems,
  );
  final DateTimePeriod? duration = _value(
    component,
    'DURATION',
    (it) => parseIcsDuration(it.value),
    where,
    problems,
  );
  final (double, double)? geo = _value(
    component,
    'GEO',
    (it) {
      final List<String> parts = it.value.split(';');
      final double? latitude = parts.length == 2
          ? double.tryParse(parts[0])
          : null;
      final double? longitude = parts.length == 2
          ? double.tryParse(parts[1])
          : null;
      if (latitude == null || longitude == null) {
        throw FormatException('Not a position', it.value);
      }
      return (latitude, longitude);
    },
    where,
    problems,
  );
  final IcsProperty? organizer = component.property('ORGANIZER');
  final IcsProperty? recurrence = component.property('RECURRENCE-ID');
  final String? classification = component.property('CLASS')?.value;
  final String? status = component.property('STATUS')?.value;
  final categories = <String>[
    for (final IcsProperty property in component.all('CATEGORIES'))
      for (final String part in splitIcsList(property.value))
        if (part.isNotEmpty) unescapeIcsText(part),
  ];
  final List<IcsDateTime> dates = _dates(
    component,
    'RDATE',
    where,
    problems,
  ).map((it) => _zoned(it, floatingZone)!).toList();
  final List<IcsDateTime> exceptions = _dates(
    component,
    'EXDATE',
    where,
    problems,
  ).map((it) => _zoned(it, floatingZone)!).toList();
  final extra = <IcsProperty>[
    for (final IcsProperty property in component.properties)
      if (!_entryProperties.contains(property.name)) property,
  ];
  final nested = <IcsComponent>[
    for (final IcsComponent child in component.components)
      if (child.name != 'VALARM') child,
  ];
  final alarms = <IcsAlarm>[
    for (final IcsComponent child in component.children('VALARM'))
      ?_alarm(child, '$where VALARM', problems),
  ];
  final List<IcsAttendee> attendees = component
      .all('ATTENDEE')
      .map(_attendee)
      .toList();
  final IcsOrganizer? organiser = organizer == null
      ? null
      : IcsOrganizer(
          organizer.value,
          name: organizer.parameter('CN'),
          sentBy: organizer.parameter('SENT-BY'),
        );
  final List<RecurrenceRule> rules = _rules(component, where, problems);
  final future =
      recurrence?.parameter('RANGE')?.toUpperCase() == 'THISANDFUTURE';
  final IcsDateTime? recurrenceId = date('RECURRENCE-ID');
  if (component.name == 'VTODO') {
    return IcsTodo(
      uid: uid,
      stamp: instant('DTSTAMP'),
      start: date('DTSTART'),
      due: date('DUE'),
      duration: duration,
      completed: instant('COMPLETED'),
      percentComplete: number('PERCENT-COMPLETE'),
      summary: text('SUMMARY'),
      description: text('DESCRIPTION'),
      location: text('LOCATION'),
      status: status == null ? null : IcsTodoStatus(status.toUpperCase()),
      classification: classification == null
          ? null
          : IcsClassification(classification.toUpperCase()),
      categories: categories,
      organizer: organiser,
      attendees: attendees,
      alarms: alarms,
      rules: rules,
      dates: dates,
      exceptions: exceptions,
      recurrenceId: recurrenceId,
      thisAndFuture: future,
      sequence: number('SEQUENCE'),
      created: instant('CREATED'),
      lastModified: instant('LAST-MODIFIED'),
      url: component.property('URL')?.value,
      priority: number('PRIORITY'),
      geo: geo,
      color: component.property('COLOR')?.value,
      properties: extra,
      components: nested,
    );
  }
  final String? transparency = component.property('TRANSP')?.value;
  return IcsEvent(
    uid: uid,
    stamp: instant('DTSTAMP'),
    start: date('DTSTART'),
    end: date('DTEND'),
    duration: duration,
    summary: text('SUMMARY'),
    description: text('DESCRIPTION'),
    location: text('LOCATION'),
    status: status == null ? null : IcsEventStatus(status.toUpperCase()),
    transparency: transparency == null
        ? null
        : IcsTransparency(transparency.toUpperCase()),
    classification: classification == null
        ? null
        : IcsClassification(classification.toUpperCase()),
    categories: categories,
    organizer: organiser,
    attendees: attendees,
    alarms: alarms,
    rules: rules,
    dates: dates,
    exceptions: exceptions,
    recurrenceId: recurrenceId,
    thisAndFuture: future,
    sequence: number('SEQUENCE'),
    created: instant('CREATED'),
    lastModified: instant('LAST-MODIFIED'),
    url: component.property('URL')?.value,
    priority: number('PRIORITY'),
    geo: geo,
    color: component.property('COLOR')?.value,
    properties: extra,
    components: nested,
  );
}

/// [value] in the zone [floatingZone] when it floats and a zone is given.
IcsDateTime? _zoned(IcsDateTime? value, String? floatingZone) {
  if (value is IcsFloatingDateTime && floatingZone != null) {
    return IcsZonedDateTime(value.local, floatingZone);
  }
  return value;
}

/// The moment of [value], a zoned or floating one read in UTC unless its
/// zone is known to the database.
Instant? _instantOf(IcsDateTime? value) => value?.toInstant(TimeZone.ofOrNull);

/// Reads the property [name] of [component] with [parse], adding a
/// problem under [where] when it cannot.
///
/// Returns the value, or `null` when the property is missing or unusable.
T? _value<T extends Object>(
  IcsComponent component,
  String name,
  T Function(IcsProperty property) parse,
  String where,
  List<String> problems,
) {
  final IcsProperty? property = component.property(name);
  if (property == null) {
    return null;
  }
  try {
    return parse(property);
  } on Exception catch (error) {
    problems.add('$where: $name: $error');
    return null;
  }
}

/// Reads the recurrence rules of [component].
List<RecurrenceRule> _rules(
  IcsComponent component,
  String where,
  List<String> problems,
) => <RecurrenceRule>[
  for (final IcsProperty property in component.all('RRULE'))
    ?_value(
      IcsComponent('RULE', properties: <IcsProperty>[property]),
      'RRULE',
      (it) => RecurrenceRule.parse(it.value),
      where,
      problems,
    ),
];

/// Reads every date of the list properties [name] of [component]; of a
/// period only its start is kept, with a problem.
List<IcsDateTime> _dates(
  IcsComponent component,
  String name,
  String where,
  List<String> problems,
) {
  final result = <IcsDateTime>[];
  for (final IcsProperty property in component.all(name)) {
    for (final String part in splitIcsList(property.value)) {
      final int slash = part.indexOf('/');
      if (slash >= 0) {
        problems.add('$where: $name: a period keeps only its start');
      }
      final IcsDateTime? value = _value(
        IcsComponent('DATE', properties: <IcsProperty>[property]),
        property.name,
        (it) =>
            parseIcsDateTime(slash >= 0 ? part.substring(0, slash) : part, it),
        where,
        problems,
      );
      if (value != null) {
        result.add(value);
      }
    }
  }
  return result;
}

/// Reads an `ATTENDEE` [property].
IcsAttendee _attendee(IcsProperty property) {
  final String? role = property.parameter('ROLE');
  final String? participation = property.parameter('PARTSTAT');
  final String? userType = property.parameter('CUTYPE');
  return IcsAttendee(
    property.value,
    name: property.parameter('CN'),
    role: role == null ? null : IcsRole(role.toUpperCase()),
    participation: participation == null
        ? null
        : IcsParticipation(participation.toUpperCase()),
    userType: userType == null ? null : IcsUserType(userType.toUpperCase()),
    rsvp: property.parameter('RSVP')?.toUpperCase() == 'TRUE',
    delegatedTo: property.parameters['DELEGATED-TO'] ?? const <String>[],
    delegatedFrom: property.parameters['DELEGATED-FROM'] ?? const <String>[],
    sentBy: property.parameter('SENT-BY'),
    members: property.parameters['MEMBER'] ?? const <String>[],
  );
}

/// Reads the alarm [component], or `null` with a problem under [where]
/// when it has no trigger.
IcsAlarm? _alarm(IcsComponent component, String where, List<String> problems) {
  final IcsTrigger? trigger = _value(
    component,
    'TRIGGER',
    (it) {
      if (it.parameter('VALUE')?.toUpperCase() == 'DATE-TIME') {
        return IcsAbsoluteTrigger(
          parseIcsDateTime(it.value, it).toInstant(TimeZone.ofOrNull),
        );
      }
      return IcsRelativeTrigger(
        parseIcsDuration(it.value),
        fromEnd: it.parameter('RELATED')?.toUpperCase() == 'END',
      );
    },
    where,
    problems,
  );
  if (trigger == null) {
    problems.add('$where: no usable TRIGGER');
    return null;
  }
  final IcsProperty? description = component.property('DESCRIPTION');
  final IcsProperty? summary = component.property('SUMMARY');
  return IcsAlarm(
    action: IcsAlarmAction(
      (component.property('ACTION')?.value ?? IcsAlarmAction.display.value)
          .toUpperCase(),
    ),
    trigger: trigger,
    description: description == null
        ? null
        : unescapeIcsText(description.value),
    summary: summary == null ? null : unescapeIcsText(summary.value),
    repeat: _value(
      component,
      'REPEAT',
      (it) =>
          int.tryParse(it.value.trim()) ??
          (throw FormatException('Not a number', it.value)),
      where,
      problems,
    ),
    repeatEvery: _value(
      component,
      'DURATION',
      (it) => parseIcsDuration(it.value),
      where,
      problems,
    ),
    attendees: component.all('ATTENDEE').map(_attendee).toList(),
    properties: <IcsProperty>[
      for (final IcsProperty property in component.properties)
        if (!const <String>{
          'ACTION',
          'TRIGGER',
          'DESCRIPTION',
          'SUMMARY',
          'REPEAT',
          'DURATION',
          'ATTENDEE',
        }.contains(property.name))
          property,
    ],
  );
}
