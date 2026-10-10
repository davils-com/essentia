/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/icalendar/ics_property.dart';
import 'package:essentia/src/icalendar/internal/ics_equality.dart';
import 'package:essentia/src/recurrence/recurrence_rule.dart';
import 'package:essentia/src/time/local_date_time.dart';
import 'package:essentia/src/time/utc_offset.dart';
import 'package:meta/meta.dart';

/// One kind of time a `VTIMEZONE` describes, its `STANDARD` or `DAYLIGHT`
/// part: from [start] on, and again by [rules] and on [dates], the clocks
/// shift from [offsetFrom] to [offsetTo].
@immutable
final class IcsTimeZoneObservance {
  /// The observance that first shifts at [start], read on the clocks of
  /// [offsetFrom].
  IcsTimeZoneObservance({
    required this.daylight,
    required this.start,
    required this.offsetFrom,
    required this.offsetTo,
    List<RecurrenceRule> rules = const <RecurrenceRule>[],
    List<LocalDateTime> dates = const <LocalDateTime>[],
    List<String> names = const <String>[],
    List<IcsProperty> properties = const <IcsProperty>[],
  }) : rules = List<RecurrenceRule>.unmodifiable(rules),
       dates = List<LocalDateTime>.unmodifiable(dates),
       names = List<String>.unmodifiable(names),
       properties = List<IcsProperty>.unmodifiable(properties);

  /// Whether this is daylight saving time rather than standard time.
  final bool daylight;

  /// The first shift into this time, on the clocks before it, `DTSTART`.
  final LocalDateTime start;

  /// The offset before each shift, `TZOFFSETFROM`.
  final UtcOffset offsetFrom;

  /// The offset after each shift, `TZOFFSETTO`.
  final UtcOffset offsetTo;

  /// The rules of the later shifts, `RRULE`.
  final List<RecurrenceRule> rules;

  /// Further shifts, `RDATE`.
  final List<LocalDateTime> dates;

  /// The abbreviations, such as `CEST`, `TZNAME`.
  final List<String> names;

  /// The properties this library does not read, as written.
  final List<IcsProperty> properties;

  /// The values that make the observance, for equality.
  List<Object?> get _values => <Object?>[
    daylight,
    start,
    offsetFrom,
    offsetTo,
    rules,
    dates,
    names,
    properties,
  ];

  /// Whether [other] is the same observance.
  @override
  bool operator ==(Object other) =>
      other is IcsTimeZoneObservance && sameIcsValues(other._values, _values);

  /// A hash of the observance.
  @override
  int get hashCode => hashIcsValues(_values);

  /// Describes the observance.
  @override
  String toString() =>
      'IcsTimeZoneObservance(${daylight ? 'daylight' : 'standard'}, $start, '
      '$offsetFrom -> $offsetTo, $rules)';
}
