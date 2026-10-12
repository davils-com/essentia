/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_time/src/date/day_of_week.dart';
import 'package:essentia_time/src/date/month.dart';
import 'package:essentia_time/src/instant.dart';
import 'package:essentia_time/src/zone/recurring_zone_rule.dart';
import 'package:essentia_time/src/zone/utc_offset.dart';
import 'package:essentia_time/src/zone/zone_rules.dart';
import 'package:essentia_time/src/zone/zone_time_definition.dart';
import 'package:essentia_time/src/zone/zone_transition.dart';
import 'package:essentia_time/src/zone/zone_transition_rule.dart';
import 'package:meta/meta.dart';

/// The 64 characters a number of the compact zone format is written in;
/// none of them needs escaping in a Dart string.
const _alphabet =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

/// The bits of payload one character carries; the sixth bit says another
/// character follows.
const _payload = 32;

/// Writes [rules] in the compact format of the built-in database.
///
/// The format is a row of unsigned numbers, five bits per character with
/// arithmetic only, so it decodes the same on the web: the table of
/// offsets, the index of the initial offset, the transitions as time
/// deltas joined with the index of their new offset, and the recurring
/// rule.
@internal
String encodeZone(ZoneRules rules) {
  final List<int> offsets = <int>{
    rules.initialOffset.totalSeconds,
    for (final ZoneTransition transition in rules.transitions)
      transition.offsetAfter.totalSeconds,
  }.toList();
  final out = StringBuffer();
  void write(int value) {
    var rest = value;
    while (rest >= _payload) {
      out.write(_alphabet[rest % _payload + _payload]);
      rest = rest ~/ _payload;
    }
    out.write(_alphabet[rest]);
  }

  void writeSigned(int value) => write(_zigzag(value));

  write(offsets.length);
  offsets.forEach(writeSigned);
  write(offsets.indexOf(rules.initialOffset.totalSeconds));
  write(rules.transitions.length);
  var previous = 0;
  for (final ZoneTransition transition in rules.transitions) {
    final int delta = transition.instant.epochSeconds - previous;
    previous = transition.instant.epochSeconds;
    final int time = delta % 60 == 0
        ? _zigzag(delta ~/ 60) * 2
        : _zigzag(delta) * 2 + 1;
    write(
      time * offsets.length +
          offsets.indexOf(transition.offsetAfter.totalSeconds),
    );
  }
  final RecurringZoneRule? recurring = rules.recurring;
  if (recurring == null) {
    write(0);
    return out.toString();
  }
  write(1);
  writeSigned(recurring.standardOffset.totalSeconds);
  write(recurring.rules.length);
  for (final ZoneTransitionRule rule in recurring.rules) {
    write(rule.month.number);
    writeSigned(rule.day);
    write(rule.dayOfWeek == null ? 0 : rule.dayOfWeek!.isoDayNumber);
    write(rule.onOrBefore ? 1 : 0);
    writeSigned(rule.timeOfDaySeconds);
    write(rule.definition.index);
    writeSigned(rule.offsetAfter.totalSeconds);
  }
  return out.toString();
}

/// Reads rules written by [encodeZone].
///
/// Throws a [FormatException] for text it did not write.
@internal
ZoneRules decodeZone(String data) {
  var position = 0;
  int read() {
    var value = 0;
    var scale = 1;
    while (true) {
      if (position >= data.length) {
        throw FormatException('Truncated zone data', data, position);
      }
      final int digit = _alphabet.indexOf(data[position]);
      position += 1;
      if (digit < 0) {
        throw FormatException('Not zone data', data, position - 1);
      }
      if (digit < _payload) {
        return value + digit * scale;
      }
      value += (digit - _payload) * scale;
      scale *= _payload;
    }
  }

  int readSigned() => _unzigzag(read());

  final offsets = <UtcOffset>[
    for (int index = read(); index > 0; index -= 1)
      UtcOffset.fromTotalSeconds(readSigned()),
  ];
  final UtcOffset initial = offsets[read()];
  final transitions = <ZoneTransition>[];
  var before = initial;
  var seconds = 0;
  for (int index = read(); index > 0; index -= 1) {
    final int value = read();
    final UtcOffset after = offsets[value % offsets.length];
    final int time = value ~/ offsets.length;
    seconds += time.isEven ? _unzigzag(time ~/ 2) * 60 : _unzigzag(time ~/ 2);
    transitions.add(
      ZoneTransition(Instant.fromEpochSeconds(seconds), before, after),
    );
    before = after;
  }
  if (read() == 0) {
    return ZoneRules(initialOffset: initial, transitions: transitions);
  }
  final standard = UtcOffset.fromTotalSeconds(readSigned());
  final rules = <ZoneTransitionRule>[
    for (int index = read(); index > 0; index -= 1) _readRule(read, readSigned),
  ];
  return ZoneRules(
    initialOffset: initial,
    transitions: transitions,
    recurring: RecurringZoneRule(standardOffset: standard, rules: rules),
  );
}

/// Reads one yearly rule through [read] and [readSigned].
ZoneTransitionRule _readRule(int Function() read, int Function() readSigned) {
  final Month month = Month.of(read());
  final int day = readSigned();
  final int weekday = read();
  final onOrBefore = read() == 1;
  final int time = readSigned();
  final ZoneTimeDefinition definition = ZoneTimeDefinition.values[read()];
  return ZoneTransitionRule(
    month: month,
    day: day,
    dayOfWeek: weekday == 0 ? null : DayOfWeek.of(weekday),
    onOrBefore: onOrBefore,
    timeOfDay: Duration(seconds: time),
    definition: definition,
    offsetAfter: UtcOffset.fromTotalSeconds(readSigned()),
  );
}

/// [value] mapped to an unsigned number, small for a small magnitude
/// either way.
int _zigzag(int value) => value >= 0 ? value * 2 : -value * 2 - 1;

/// The signed number [_zigzag] mapped to [value].
int _unzigzag(int value) => value.isEven ? value ~/ 2 : -(value + 1) ~/ 2;
