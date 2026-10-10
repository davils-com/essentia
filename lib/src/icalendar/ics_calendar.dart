/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/icalendar/ics_component.dart';
import 'package:essentia/src/icalendar/ics_entry.dart';
import 'package:essentia/src/icalendar/ics_property.dart';
import 'package:essentia/src/icalendar/ics_time_zone.dart';
import 'package:essentia/src/icalendar/ics_zone_resolver.dart';
import 'package:essentia/src/icalendar/internal/ics_equality.dart';
import 'package:meta/meta.dart';

/// An iCalendar file, the `VCALENDAR` of RFC 5545: its events, to-dos and
/// time zones, and everything else it holds kept as written.
@immutable
final class IcsCalendar {
  /// The calendar of [events], [todos] and [timeZones].
  IcsCalendar({
    this.productId,
    this.method,
    this.scale,
    this.name,
    List<IcsEvent> events = const <IcsEvent>[],
    List<IcsTodo> todos = const <IcsTodo>[],
    List<IcsTimeZone> timeZones = const <IcsTimeZone>[],
    List<IcsProperty> properties = const <IcsProperty>[],
    List<IcsComponent> components = const <IcsComponent>[],
  }) : events = List<IcsEvent>.unmodifiable(events),
       todos = List<IcsTodo>.unmodifiable(todos),
       timeZones = List<IcsTimeZone>.unmodifiable(timeZones),
       properties = List<IcsProperty>.unmodifiable(properties),
       components = List<IcsComponent>.unmodifiable(components);

  /// Who wrote the file, `PRODID`.
  final String? productId;

  /// What the file asks of its reader, such as `REQUEST`, `METHOD`.
  final String? method;

  /// The calendar system, `CALSCALE`; Gregorian when not given.
  final String? scale;

  /// The name of the calendar, `NAME` of RFC 7986 or `X-WR-CALNAME`.
  final String? name;

  /// The events.
  final List<IcsEvent> events;

  /// The to-dos.
  final List<IcsTodo> todos;

  /// The time zones the file describes.
  final List<IcsTimeZone> timeZones;

  /// The properties this library does not read, as written.
  final List<IcsProperty> properties;

  /// The components this library does not read, such as `VJOURNAL`, as
  /// written.
  final List<IcsComponent> components;

  /// Every entry, events first.
  List<IcsEntry> get entries => <IcsEntry>[...events, ...todos];

  /// The resolver of the zones the entries name, built on [timeZones].
  IcsZoneResolver get zones => IcsZoneResolver(timeZones);

  /// The values that make the calendar, for equality.
  List<Object?> get _values => <Object?>[
    productId,
    method,
    scale,
    name,
    events,
    todos,
    timeZones,
    properties,
    components,
  ];

  /// Whether [other] is the same calendar.
  @override
  bool operator ==(Object other) =>
      other is IcsCalendar && sameIcsValues(other._values, _values);

  /// A hash of the calendar.
  @override
  int get hashCode => hashIcsValues(_values);

  /// Describes the calendar briefly.
  @override
  String toString() =>
      'IcsCalendar($name, ${events.length} events, ${todos.length} todos)';
}
