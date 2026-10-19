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

import 'package:essentia_core/src/version/internal/interval_algebra.dart';
import 'package:essentia_core/src/version/internal/operator.dart';
import 'package:essentia_core/src/version/internal/partial.dart';
import 'package:essentia_core/src/version/internal/partial_grammar.dart';
import 'package:essentia_core/src/version/internal/partial_reading.dart';
import 'package:essentia_core/src/version/internal/range_grammar.dart';
import 'package:essentia_core/src/version/internal/range_reading.dart';
import 'package:essentia_core/src/version/internal/shorthands.dart';
import 'package:essentia_core/src/version/version_interval.dart';
import 'package:meta/meta.dart';

/// Why an operator without an operand is refused.
const _danglingOperatorReason = 'has an operator with no version after it';

/// Why a misshapen hyphen range is refused.
const _hyphenReason = 'has a hyphen range that is not written like 1.2 - 1.4';

/// What the reason of a comparator that is no version starts with.
const _comparatorReason = 'has a comparator that is not a version: it';

/// The token of a hyphen range.
const _hyphen = '-';

/// How many tokens a hyphen range has.
const _hyphenTokens = 3;

/// What separates the comparators of a set: a space, a tab, a line feed, a
/// vertical tab, a form feed or a carriage return.
final _whitespace = RegExp('[ \t\n\x0B\f\r]+');

/// How every operator is written.
final _operatorSymbols = <String>{
  for (final operator in Operator.values) operator.symbol,
};

/// Reads [text], one alternative in npm notation, as the comparators it
/// lists, every one of which a version has to satisfy; or as a hyphen
/// range.
///
/// Returns the intervals read, or why [text] is not a range or matches no
/// version.
@internal
RangeReading readComparatorSet(String text) {
  final List<String> tokens = text.split(_whitespace);
  if (tokens.contains(_hyphen)) {
    return _readHyphen(tokens);
  }
  final List<String>? comparators = _joinedOperators(tokens);
  if (comparators == null) {
    return const RangeRefused(_danglingOperatorReason);
  }

  var matching = <VersionInterval>[everything];
  for (final String comparator in comparators) {
    final RangeReading reading = _readComparator(comparator);
    switch (reading) {
      case RangeRead():
        matching = intersection(matching, reading.intervals);
      case RangeRefused():
        return reading;
    }
  }
  if (matching.isEmpty) {
    return const RangeRefused(matchesNothingReason);
  }
  return RangeRead(matching);
}

/// Joins every token of [tokens] that is a bare operator to the operand
/// after it, so that `>= 1.2.3` reads as `>=1.2.3`.
///
/// Returns the comparators, or `null` when an operator ends the list.
List<String>? _joinedOperators(List<String> tokens) {
  final joined = <String>[];
  final pending = StringBuffer();
  for (final token in tokens) {
    pending.write(token);
    if (_operatorSymbols.contains(token)) {
      continue;
    }
    joined.add(pending.toString());
    pending.clear();
  }
  if (pending.isNotEmpty) {
    return null;
  }
  return joined;
}

/// Reads the comparator [text]: an optional operator and a partial
/// version.
///
/// Returns the interval read, none when it matches no version, or why
/// [text] is not a comparator.
RangeReading _readComparator(String text) {
  final Operator? operator = Operator.values
      .where((candidate) => text.startsWith(candidate.symbol))
      .firstOrNull;
  final String operand = operator == null
      ? text
      : text.substring(operator.symbol.length);
  final PartialReading reading = readPartial(operand);
  return switch (reading) {
    PartialRead(:final partial) => RangeRead(<VersionInterval>[
      ?intervalFor(operator, partial),
    ]),
    PartialRefused(:final reason) => _comparatorRefusal(reason),
  };
}

/// Reads [tokens] as a hyphen range, `1.2 - 1.4`.
///
/// Returns the interval read, or why [tokens] are not a hyphen range or
/// match no version.
RangeReading _readHyphen(List<String> tokens) {
  final bool shaped = tokens.length == _hyphenTokens && tokens[1] == _hyphen;
  if (!shaped) {
    return const RangeRefused(_hyphenReason);
  }
  final PartialReading from = readPartial(tokens[0]);
  final PartialReading to = readPartial(tokens[2]);
  return switch ((from, to)) {
    (PartialRefused(:final reason), PartialReading()) => _comparatorRefusal(
      reason,
    ),
    (PartialRead(), PartialRefused(:final reason)) => _comparatorRefusal(
      reason,
    ),
    (PartialRead(partial: final lowest), PartialRead(partial: final highest)) =>
      _hyphenRange(lowest, highest),
  };
}

/// The range from [lowest] to [highest], as a hyphen range means it.
///
/// Returns the interval, or why it matches no version.
RangeReading _hyphenRange(Partial lowest, Partial highest) {
  final VersionInterval? interval = hyphenInterval(lowest, highest);
  if (interval == null) {
    return const RangeRefused(matchesNothingReason);
  }
  return RangeRead(<VersionInterval>[interval]);
}

/// The refusal of a comparator whose version is wrong for [reason].
///
/// Returns the refusal.
RangeReading _comparatorRefusal(String reason) =>
    RangeRefused('$_comparatorReason $reason');
