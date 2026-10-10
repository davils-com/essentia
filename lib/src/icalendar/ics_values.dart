/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/icalendar/ics_date_time.dart';
import 'package:essentia/src/icalendar/ics_property.dart';
import 'package:essentia/src/time/date_time_period.dart';
import 'package:essentia/src/time/internal/iso_text.dart';
import 'package:essentia/src/time/local_date.dart';
import 'package:essentia/src/time/local_date_time.dart';
import 'package:essentia/src/time/local_time.dart';
import 'package:essentia/src/time/utc_offset.dart';

/// Reads the date or date and time [text] of a property with the
/// parameters of [property]: `VALUE=DATE` or eight digits make a day, a
/// `Z` a moment in UTC, a `TZID` a zoned time, else a floating one.
///
/// Throws a [FormatException] for any other text.
IcsDateTime parseIcsDateTime(String text, IcsProperty property) {
  final String value = text.trim();
  final RegExpMatch? match = RegExp(
    r'^(\d{4})(\d{2})(\d{2})(?:T(\d{2})(\d{2})(\d{2})(Z)?)?$',
  ).firstMatch(value);
  if (match == null) {
    throw FormatException('Not a date or time', value);
  }
  final date = LocalDate.parse(
    '${match.group(1)}-${match.group(2)}-${match.group(3)}',
  );
  if (match.group(4) == null) {
    return IcsDate(date);
  }
  final int second = int.parse(match.group(6)!);
  final local = LocalDateTime(
    date,
    LocalTime.parse(
      '${match.group(4)}:${match.group(5)}:'
      '${twoDigits(second > 59 ? 59 : second)}',
    ),
  );
  if (match.group(7) != null) {
    return IcsUtcDateTime(local.toInstantAt(UtcOffset.zero));
  }
  final String? zone = property.parameter('TZID');
  if (zone != null) {
    return IcsZonedDateTime(local, zone);
  }
  return IcsFloatingDateTime(local);
}

/// The property [name] of [value]: its text and the `VALUE` or `TZID`
/// parameter it needs.
IcsProperty icsDateTimeProperty(String name, IcsDateTime value) =>
    icsDateTimeListProperty(name, <IcsDateTime>[value]);

/// The property [name] of the list [values], which must share their kind
/// and zone.
IcsProperty icsDateTimeListProperty(String name, List<IcsDateTime> values) {
  final IcsDateTime first = values.first;
  final String text = values.map(formatIcsDateTime).join(',');
  return switch (first) {
    IcsDate() => IcsProperty(
      name,
      text,
      parameters: const <String, List<String>>{
        'VALUE': <String>['DATE'],
      },
    ),
    IcsZonedDateTime(:final String zoneId) => IcsProperty(
      name,
      text,
      parameters: <String, List<String>>{
        'TZID': <String>[zoneId],
      },
    ),
    IcsUtcDateTime() || IcsFloatingDateTime() => IcsProperty(name, text),
  };
}

/// [value] as RFC 5545 writes it, without its parameters.
String formatIcsDateTime(IcsDateTime value) => switch (value) {
  IcsDate(:final LocalDate date) => _date(date),
  IcsUtcDateTime() => '${_dateTime(value.local)}Z',
  IcsZonedDateTime(:final LocalDateTime local) ||
  IcsFloatingDateTime(:final LocalDateTime local) => _dateTime(local),
};

/// [date] as eight digits.
String _date(LocalDate date) =>
    '${padDigits(date.year, 4)}${twoDigits(date.monthNumber)}'
    '${twoDigits(date.day)}';

/// [local] as RFC 5545 writes a date and time.
String _dateTime(LocalDateTime local) =>
    '${_date(local.date)}T${twoDigits(local.hour)}'
    '${twoDigits(local.minute)}${twoDigits(local.second)}';

/// Reads a duration as RFC 5545 writes it: `P1W`, `PT15M`, `-P1DT2H`.
///
/// Throws a [FormatException] for any other text, months and years
/// included.
DateTimePeriod parseIcsDuration(String text) {
  final String value = text.trim();
  if (value.contains('Y') ||
      RegExp('P[^T]*M').hasMatch(value) ||
      !value.contains('P')) {
    throw FormatException('Not a duration', value);
  }
  return DateTimePeriod.parse(value);
}

/// [period] as RFC 5545 writes a duration.
///
/// Throws an [ArgumentError] for a period of months or years, which a
/// duration cannot hold, or of mixed signs.
String formatIcsDuration(DateTimePeriod period) {
  if (period.totalMonths != 0) {
    throw ArgumentError.value(period, 'period', 'Has months or years');
  }
  final bool negative = period.days < 0 || period.secondsOfTime < 0;
  final int days = period.days.abs();
  final int seconds = period.secondsOfTime.abs();
  final bool mixed =
      (period.days > 0 && period.secondsOfTime < 0) ||
      (period.days < 0 && period.secondsOfTime > 0);
  if (mixed) {
    throw ArgumentError.value(period, 'period', 'Has mixed signs');
  }
  final buffer = StringBuffer(negative ? '-P' : 'P');
  if (seconds == 0 && days != 0 && days % 7 == 0) {
    return '$buffer${days ~/ 7}W';
  }
  if (days != 0 || seconds == 0) {
    buffer.write('${days}D');
  }
  if (seconds != 0) {
    buffer.write('T');
    if (seconds >= 3600) {
      buffer.write('${seconds ~/ 3600}H');
    }
    if (seconds % 3600 >= 60) {
      buffer.write('${seconds % 3600 ~/ 60}M');
    }
    if (seconds % 60 != 0) {
      buffer.write('${seconds % 60}S');
    }
  }
  return buffer.toString();
}

/// Reads a UTC offset as RFC 5545 writes it: `+0100`, `-053000`.
///
/// Throws a [FormatException] for any other text.
UtcOffset parseIcsOffset(String text) => UtcOffset.parse(text.trim());

/// [offset] as RFC 5545 writes it: `+0100`, with seconds when it has any.
String formatIcsOffset(UtcOffset offset) {
  final int total = offset.totalSeconds.abs();
  final sign = offset.totalSeconds < 0 ? '-' : '+';
  final String seconds = total % 60 == 0 ? '' : twoDigits(total % 60);
  return '$sign${twoDigits(total ~/ 3600)}${twoDigits(total ~/ 60 % 60)}'
      '$seconds';
}
