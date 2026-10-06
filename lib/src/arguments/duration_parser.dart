/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

/// The microseconds of each unit of the readable form, largest first.
const _readableUnits = <String, int>{
  'd': Duration.microsecondsPerDay,
  'h': Duration.microsecondsPerHour,
  'm': Duration.microsecondsPerMinute,
  's': Duration.microsecondsPerSecond,
  'ms': Duration.microsecondsPerMillisecond,
  'us': 1,
};

/// One component of the readable form: a number and a unit.
final _readableComponent = RegExp(r'(\d+(?:\.\d+)?)\s*(ms|us|ns|d|h|m|s)');

/// The ISO-8601 form, with days, hours, minutes and seconds.
final _isoDuration = RegExp(
  r'^P(?:(\d+(?:\.\d+)?)D)?(?:T(?:(\d+(?:\.\d+)?)H)?(?:(\d+(?:\.\d+)?)M)?'
  r'(?:(\d+(?:\.\d+)?)S)?)?$',
  caseSensitive: false,
);

/// Reads a duration written the readable way (`30s`, `1h 30m`, `250ms`)
/// or in ISO-8601 (`PT30S`, `P1DT2H`), optionally negative.
///
/// Returns the duration, or `null` when [raw] is neither.
@internal
Duration? parseDuration(String raw) {
  final String text = raw.trim();
  final bool negative = text.startsWith('-');
  final String body = negative ? text.substring(1).trim() : text;
  final double? microseconds =
      _isoMicroseconds(body) ?? _readableMicroseconds(body);
  if (microseconds == null) {
    return null;
  }
  final duration = Duration(microseconds: microseconds.round());
  return negative ? -duration : duration;
}

/// Reads [text] as an ISO-8601 duration.
///
/// Returns the microseconds, or `null` when it is not one.
double? _isoMicroseconds(String text) {
  final RegExpMatch? match = _isoDuration.firstMatch(text);
  if (match == null) {
    return null;
  }
  final parts = <String?>[
    match.group(1),
    match.group(2),
    match.group(3),
    match.group(4),
  ];
  final bool hasTime = text.toUpperCase().contains('T');
  final bool timeIsEmpty =
      hasTime && parts.skip(1).every((part) => part == null);
  if (parts.every((part) => part == null) || timeIsEmpty) {
    return null;
  }
  const units = <int>[
    Duration.microsecondsPerDay,
    Duration.microsecondsPerHour,
    Duration.microsecondsPerMinute,
    Duration.microsecondsPerSecond,
  ];
  var total = 0.0;
  for (var index = 0; index < parts.length; index++) {
    final String? part = parts[index];
    if (part != null) {
      total += double.parse(part) * units[index];
    }
  }
  return total;
}

/// Reads [text] as components of a number and a unit, each unit at most
/// once and largest first.
///
/// Returns the microseconds, or `null` when it is not that form.
double? _readableMicroseconds(String text) {
  if (text.isEmpty) {
    return null;
  }
  final order = <String>[..._readableUnits.keys, 'ns'];
  var position = 0;
  var lastUnit = -1;
  var total = 0.0;
  for (final RegExpMatch match in _readableComponent.allMatches(text)) {
    final bool contiguous = text
        .substring(position, match.start)
        .trim()
        .isEmpty;
    final int unit = order.indexOf(match.group(2)!);
    if (!contiguous || unit <= lastUnit) {
      return null;
    }
    final double amount = double.parse(match.group(1)!);
    total += _microsecondsOf(amount, match.group(2)!);
    lastUnit = unit;
    position = match.end;
  }
  final bool consumed = text.substring(position).trim().isEmpty;
  if (lastUnit < 0 || !consumed) {
    return null;
  }
  return total;
}

/// Converts [amount] of [unit] to microseconds.
///
/// Returns the microseconds.
double _microsecondsOf(double amount, String unit) {
  final int? perUnit = _readableUnits[unit];
  if (perUnit == null) {
    return amount / 1000;
  }
  return amount * perUnit;
}
