/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/icalendar/ics_calendar.dart';
import 'package:meta/meta.dart';

/// What `IcsCodec.decode` read: the [calendars] of the file and the
/// [warnings] a lenient read passed over.
@immutable
final class IcsParseResult {
  /// The result of [calendars] and [warnings].
  IcsParseResult(List<IcsCalendar> calendars, List<String> warnings)
    : calendars = List<IcsCalendar>.unmodifiable(calendars),
      warnings = List<String>.unmodifiable(warnings);

  /// The calendars, usually one.
  final List<IcsCalendar> calendars;

  /// The problems a lenient read passed over.
  final List<String> warnings;

  /// The first calendar, or an empty one when the file held none.
  IcsCalendar get calendar =>
      calendars.isEmpty ? IcsCalendar() : calendars.first;

  /// Describes the result.
  @override
  String toString() =>
      'IcsParseResult(${calendars.length} calendars, '
      '${warnings.length} warnings)';
}
