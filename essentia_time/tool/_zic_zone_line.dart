/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

part of 'generate_tzdata.dart';

/// A line of a `Zone` of the database: its standard offset, its daylight
/// saving and when the line ends.
final class ZicZoneLine {
  /// The line of [standardOffset] seconds whose saving follows the rules
  /// [rules] or is [save] seconds, until [untilLocal].
  const ZicZoneLine({
    required this.standardOffset,
    required this.rules,
    required this.save,
    required this.untilYear,
    required this.untilLocal,
    required this.untilDefinition,
  });

  /// Reads the fields of a zone line after the zone name: STDOFF, RULES,
  /// FORMAT and the optional UNTIL.
  ///
  /// Throws a [FormatException] for fields it cannot read.
  factory ZicZoneLine.parse(List<String> fields) {
    final String rules = fields[1];
    final bool named = rules != '-' && !RegExp(r'^-?\d').hasMatch(rules);
    final List<String> until = fields.sublist(3);
    final int? year = until.isEmpty ? null : int.parse(until[0]);
    final Month month = until.length > 1
        ? ZicRule.parseMonth(until[1])
        : Month.january;
    final (int day, DayOfWeek? dayOfWeek, bool onOrBefore) = until.length > 2
        ? ZicRule.parseDay(until[2])
        : (1, null, false);
    final time = until.length > 3
        ? ZicTime.parse(until[3])
        : const ZicTime(0, ZoneTimeDefinition.wall);
    final int local = year == null
        ? 0
        : ZicRule(
            from: year,
            to: year,
            month: month,
            day: day,
            dayOfWeek: dayOfWeek,
            onOrBefore: onOrBefore,
            at: time,
            save: 0,
          ).localSecondsIn(year);
    return ZicZoneLine(
      standardOffset: ZicTime.parse(fields[0]).seconds,
      rules: named ? rules : null,
      save: named || rules == '-' ? 0 : ZicTime.parse(rules).seconds,
      untilYear: year,
      untilLocal: local,
      untilDefinition: time.definition,
    );
  }

  /// The standard offset in seconds.
  final int standardOffset;

  /// The name of the rules the saving follows, or `null` for a fixed
  /// [save].
  final String? rules;

  /// The fixed saving in seconds when there are no [rules].
  final int save;

  /// The year the line ends in, or `null` for the last line.
  final int? untilYear;

  /// The local seconds since the epoch at which the line ends, read on
  /// [untilDefinition].
  final int untilLocal;

  /// The clock the end is read on.
  final ZoneTimeDefinition untilDefinition;

  /// The epoch second the line ends at while [save] seconds are saved.
  int untilUtc(int save) =>
      ZicTime.toUtc(untilLocal, untilDefinition, standardOffset, save);
}
