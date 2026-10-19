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
import 'package:essentia_time/src/date/local_date_time.dart';
import 'package:essentia_time/src/instant.dart';
import 'package:essentia_time/src/internal/time_math.dart';
import 'package:essentia_time/src/zone/recurring_zone_rule.dart';
import 'package:essentia_time/src/zone/utc_offset.dart';
import 'package:essentia_time/src/zone/zone_offset_info.dart';
import 'package:essentia_time/src/zone/zone_transition.dart';
import 'package:meta/meta.dart';

/// The offsets a time zone has over time: an [initialOffset], the
/// [transitions] of its history and, once that ends, the [recurring]
/// shifts of every following year.
///
/// The rules of every zone of the time zone database are built in;
/// `TimeZone.fromRules` makes a zone of rules from elsewhere, such as the
/// time zone of a calendar file.
@immutable
final class ZoneRules {
  /// The rules of a zone that starts at [initialOffset], shifts at
  /// [transitions] and then repeats [recurring] every year.
  ///
  /// Throws an [ArgumentError] when the transitions are out of order or do
  /// not continue from the offset before them.
  ZoneRules({
    required this.initialOffset,
    Iterable<ZoneTransition> transitions = const <ZoneTransition>[],
    this.recurring,
  }) : transitions = List<ZoneTransition>.unmodifiable(transitions) {
    UtcOffset offset = initialOffset;
    Instant? previous;
    for (final ZoneTransition transition in this.transitions) {
      final last = previous;
      if (last != null && !transition.instant.isAfter(last)) {
        throw ArgumentError('Transitions must be in time order: $transition');
      }
      if (transition.offsetBefore != offset) {
        throw ArgumentError(
          'Transition $transition does not continue from $offset',
        );
      }
      offset = transition.offsetAfter;
      previous = transition.instant;
    }
  }

  /// The rules of a zone that always has [offset].
  factory ZoneRules.fixed(UtcOffset offset) => ZoneRules(initialOffset: offset);

  /// The offset before the first transition.
  final UtcOffset initialOffset;

  /// The transitions of the history of the zone, in time order.
  final List<ZoneTransition> transitions;

  /// The shifts of every year after the last of [transitions], or `null`
  /// when the offset stays put.
  final RecurringZoneRule? recurring;

  /// The transitions [recurring] yields in a year, by year.
  final _years = <int, List<ZoneTransition>>{};

  /// How many years of [_years] are kept.
  static const _yearCacheSize = 64;

  /// How far around a local time its transitions are looked for, in
  /// seconds: two days, beyond any offset.
  static const int _reach = 2 * secondsPerDay;

  /// Whether the zone always has one offset.
  bool get isFixed => transitions.isEmpty && recurring == null;

  /// The epoch second of the last transition of the history, or `null`
  /// when there is none.
  int? get _lastHistorySecond =>
      transitions.isEmpty ? null : transitions.last.instant.epochSeconds;

  /// The offset after the history.
  UtcOffset get _historyEnd =>
      transitions.isEmpty ? initialOffset : transitions.last.offsetAfter;

  /// The offset of the zone at [instant].
  UtcOffset offsetAt(Instant instant) {
    final int seconds = instant.epochSeconds;
    final int? last = _lastHistorySecond;
    if (recurring == null || (last != null && seconds < last)) {
      final int index = _lastAtOrBefore(seconds);
      return index < 0 ? initialOffset : transitions[index].offsetAfter;
    }
    final int year = _yearOf(seconds);
    UtcOffset offset = _historyEnd;
    for (final ZoneTransition transition in _recurringIn(year - 1, year)) {
      if (transition.instant.epochSeconds > seconds) {
        return offset;
      }
      offset = transition.offsetAfter;
    }
    return offset;
  }

  /// What the zone makes of [local]: one offset, or the shift that skips
  /// or repeats it.
  ZoneOffsetInfo infoAt(LocalDateTime local) {
    final int seconds = local.localEpochSeconds;
    for (final ZoneTransition transition in _between(
      seconds - _reach,
      seconds + _reach,
    )) {
      final int at = transition.instant.epochSeconds;
      final int before = at + transition.offsetBefore.totalSeconds;
      final int after = at + transition.offsetAfter.totalSeconds;
      if (transition.isGap && before <= seconds && seconds < after) {
        return GapOffsetInfo(transition);
      }
      if (transition.isOverlap && after <= seconds && seconds < before) {
        return OverlapOffsetInfo(transition);
      }
    }
    final UtcOffset guess = offsetAt(Instant.fromEpochSeconds(seconds));
    final UtcOffset offset = offsetAt(
      Instant.fromEpochSeconds(seconds - guess.totalSeconds),
    );
    return RegularOffsetInfo(offset);
  }

  /// The transitions from [from], included, up to [until], excluded.
  ///
  /// Throws an [ArgumentError] when the recurring shifts would have to be
  /// listed for more than a thousand years.
  List<ZoneTransition> transitionsBetween(Instant from, Instant until) {
    final int start = from.epochSeconds;
    final int end = until.epochSeconds;
    if (recurring != null && _yearOf(end) - _yearOf(start) > 1000) {
      throw ArgumentError('Cannot list the transitions of over 1000 years');
    }
    return <ZoneTransition>[
      for (final ZoneTransition transition in _between(start, end))
        if (!transition.instant.isBefore(from) &&
            transition.instant.isBefore(until))
          transition,
    ];
  }

  /// The first transition after [instant], or `null` when none follows.
  ZoneTransition? nextTransition(Instant instant) {
    final int seconds = instant.epochSeconds;
    final int index = _lastAtOrBefore(seconds) + 1;
    if (index < transitions.length) {
      return transitions[index];
    }
    if (recurring == null) {
      return null;
    }
    final int last = _lastHistorySecond ?? seconds;
    final int year = _yearOf(seconds > last ? seconds : last);
    for (final ZoneTransition transition in _recurringIn(year, year + 2)) {
      if (transition.instant.isAfter(instant)) {
        return transition;
      }
    }
    return null;
  }

  /// The last transition before [instant], or `null` when none precedes.
  ZoneTransition? previousTransition(Instant instant) {
    final int seconds = instant.epochSeconds;
    final int? last = _lastHistorySecond;
    if (recurring != null && (last == null || seconds > last)) {
      final int year = _yearOf(seconds);
      ZoneTransition? found;
      for (final ZoneTransition transition in _recurringIn(year - 2, year)) {
        if (transition.instant.isBefore(instant)) {
          found = transition;
        }
      }
      if (found != null) {
        return found;
      }
    }
    int index = _lastAtOrBefore(seconds);
    if (index >= 0 && !transitions[index].instant.isBefore(instant)) {
      index -= 1;
    }
    return index < 0 ? null : transitions[index];
  }

  /// The index of the last transition of the history at or before the
  /// epoch second [seconds], or -1.
  int _lastAtOrBefore(int seconds) {
    var low = 0;
    int high = transitions.length - 1;
    var found = -1;
    while (low <= high) {
      final int middle = (low + high) ~/ 2;
      if (transitions[middle].instant.epochSeconds <= seconds) {
        found = middle;
        low = middle + 1;
        continue;
      }
      high = middle - 1;
    }
    return found;
  }

  /// The transitions between the epoch seconds [start] and [end], roughly:
  /// those of the history in that span and the recurring ones of the
  /// years it touches.
  List<ZoneTransition> _between(int start, int end) {
    final result = <ZoneTransition>[];
    for (
      int index = _lastAtOrBefore(start) < 0 ? 0 : _lastAtOrBefore(start);
      index < transitions.length;
      index += 1
    ) {
      final ZoneTransition transition = transitions[index];
      if (transition.instant.epochSeconds > end) {
        break;
      }
      result.add(transition);
    }
    final int? last = _lastHistorySecond;
    if (recurring != null && (last == null || end > last)) {
      result.addAll(_recurringIn(_yearOf(start) - 1, _yearOf(end) + 1));
    }
    return result;
  }

  /// The recurring transitions of the years [first] to [last] that come
  /// after the history, in time order.
  List<ZoneTransition> _recurringIn(int first, int last) {
    final RecurringZoneRule? rule = recurring;
    if (rule == null) {
      return const <ZoneTransition>[];
    }
    final int? history = _lastHistorySecond;
    return <ZoneTransition>[
      for (int year = first; year <= last; year += 1)
        for (final ZoneTransition transition in _yearOfRule(rule, year))
          if (history == null || transition.instant.epochSeconds > history)
            transition,
    ];
  }

  /// The transitions of [rule] in [year], cached.
  List<ZoneTransition> _yearOfRule(RecurringZoneRule rule, int year) {
    final List<ZoneTransition>? cached = _years[year];
    if (cached != null) {
      return cached;
    }
    if (_years.length >= _yearCacheSize) {
      _years.clear();
    }
    return _years[year] = rule.transitionsIn(year);
  }

  /// The year of the UTC date at the epoch second [seconds].
  static int _yearOf(int seconds) =>
      LocalDate.fromEpochDays(floorDiv(seconds, secondsPerDay)).year;

  /// Whether [other] has the same offsets over time.
  @override
  bool operator ==(Object other) =>
      other is ZoneRules &&
      other.initialOffset == initialOffset &&
      other.recurring == recurring &&
      _sameTransitions(other.transitions);

  /// Whether [others] are the transitions of these rules.
  bool _sameTransitions(List<ZoneTransition> others) {
    if (others.length != transitions.length) {
      return false;
    }
    for (var index = 0; index < transitions.length; index += 1) {
      if (others[index] != transitions[index]) {
        return false;
      }
    }
    return true;
  }

  /// A hash of the rules.
  @override
  int get hashCode =>
      Object.hash(initialOffset, recurring, Object.hashAll(transitions));

  /// Describes the rules briefly.
  @override
  String toString() =>
      'ZoneRules($initialOffset, ${transitions.length} transitions, '
      '$recurring)';
}
