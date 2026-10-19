/*
 * Copyright 2026 Davils
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:essentia_time/src/date/local_date.dart';
import 'package:essentia_time/src/instant.dart';
import 'package:essentia_time/src/zone/utc_offset.dart';
import 'package:essentia_time/src/zone/zone_time_definition.dart';
import 'package:essentia_time/src/zone/zone_transition.dart';
import 'package:essentia_time/src/zone/zone_transition_rule.dart';
import 'package:meta/meta.dart';

/// The shifts of the clocks a time zone repeats every year once its
/// history ends, such as daylight saving time from the last Sunday of
/// March to the last Sunday of October.
@immutable
final class RecurringZoneRule {
  /// The yearly [rules] of a zone whose standard time is
  /// [standardOffset].
  ///
  /// Throws an [ArgumentError] when [rules] is empty.
  RecurringZoneRule({
    required this.standardOffset,
    required List<ZoneTransitionRule> rules,
  }) : rules = List<ZoneTransitionRule>.unmodifiable(rules) {
    if (rules.isEmpty) {
      throw ArgumentError.value(rules, 'rules', 'Must not be empty');
    }
  }

  /// The offset of standard time.
  final UtcOffset standardOffset;

  /// The shifts of one year.
  final List<ZoneTransitionRule> rules;

  /// The shifts in [year], in time order; a rule that does not change
  /// the offset yields none.
  List<ZoneTransition> transitionsIn(int year) {
    final ordered =
        <(int, ZoneTransitionRule)>[
          for (final ZoneTransitionRule rule in rules)
            (_localSeconds(rule, year), rule),
        ]..sort(
          ((int, ZoneTransitionRule) a, (int, ZoneTransitionRule) b) =>
              a.$1.compareTo(b.$1),
        );
    final result = <ZoneTransition>[];
    UtcOffset before = ordered.last.$2.offsetAfter;
    for (final (int local, ZoneTransitionRule rule) in ordered) {
      final int shift = switch (rule.definition) {
        ZoneTimeDefinition.wall => before.totalSeconds,
        ZoneTimeDefinition.standard => standardOffset.totalSeconds,
        ZoneTimeDefinition.utc => 0,
      };
      if (before != rule.offsetAfter) {
        result.add(
          ZoneTransition(
            Instant.fromEpochSeconds(local - shift),
            before,
            rule.offsetAfter,
          ),
        );
      }
      before = rule.offsetAfter;
    }
    return result;
  }

  /// The seconds since the epoch of the local time of [rule] in [year].
  static int _localSeconds(ZoneTransitionRule rule, int year) {
    final LocalDate date = rule.dateIn(year);
    return date.epochDays * 86400 + rule.timeOfDaySeconds;
  }

  /// Whether [other] is the same set of shifts.
  @override
  bool operator ==(Object other) =>
      other is RecurringZoneRule &&
      other.standardOffset == standardOffset &&
      _sameRules(other.rules);

  /// Whether [others] are these rules in the same order.
  bool _sameRules(List<ZoneTransitionRule> others) {
    if (others.length != rules.length) {
      return false;
    }
    for (var index = 0; index < rules.length; index += 1) {
      if (others[index] != rules[index]) {
        return false;
      }
    }
    return true;
  }

  /// A hash of the shifts.
  @override
  int get hashCode => Object.hash(standardOffset, Object.hashAll(rules));

  /// Describes the shifts.
  @override
  String toString() => 'RecurringZoneRule($standardOffset, $rules)';
}
