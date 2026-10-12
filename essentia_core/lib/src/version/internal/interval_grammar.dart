/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/version/internal/interval_algebra.dart';
import 'package:essentia_core/src/version/internal/range_reading.dart';
import 'package:essentia_core/src/version/internal/version_grammar.dart';
import 'package:essentia_core/src/version/internal/version_reading.dart';
import 'package:essentia_core/src/version/semantic_version.dart';
import 'package:essentia_core/src/version/version_interval.dart';
import 'package:meta/meta.dart';

/// Why a misshapen interval is refused.
const _intervalShapeReason =
    'has an interval that is not written like [1.2, 2.0)';

/// Why an interval with nothing in it is refused.
const _intervalEmptyReason =
    'has an interval that is empty, because its lower bound is not below '
    'its upper';

/// What the reason of a bound that is no version starts with.
const _intervalBoundReason = 'has a bound that is not a version: it';

/// How many numbers a bound has at least: `[1, 2)` is allowed.
const _shortestBound = 1;

/// What separates the two bounds of an interval.
const _boundSeparator = ',';

/// What separates two intervals.
const _intervalSeparator = ',';

/// What opens an interval that holds its lower bound.
const _inclusiveLower = '[';

/// What closes an interval that holds its upper bound.
const _inclusiveUpper = ']';

/// What an interval starts with.
const _intervalOpenings = '[(';

/// What an interval ends with.
final _intervalClosing = RegExp(r'[\])]');

/// Reads [text], one alternative in interval notation, as the intervals it
/// lists, separated by commas as Maven writes them.
///
/// Returns the intervals read, or why [text] is not a range.
@internal
RangeReading readIntervals(String text) {
  final intervals = <VersionInterval>[];
  var rest = text;
  while (rest.isNotEmpty) {
    final int closing = rest.indexOf(_intervalClosing);
    if (!_intervalOpenings.contains(rest[0]) || closing < 0) {
      return const RangeRefused(_intervalShapeReason);
    }
    final RangeReading reading = _readInterval(rest.substring(0, closing + 1));
    switch (reading) {
      case RangeRead():
        intervals.addAll(reading.intervals);
      case RangeRefused():
        return reading;
    }
    final String? next = _nextInterval(rest.substring(closing + 1));
    if (next == null) {
      return const RangeRefused(_intervalShapeReason);
    }
    rest = next;
  }
  return RangeRead(intervals);
}

/// What follows an interval, [tail], without the separator in front.
///
/// Returns the rest, empty when nothing follows, or `null` when what
/// follows is not a separated interval.
String? _nextInterval(String tail) {
  final String trimmed = tail.trim();
  if (trimmed.isEmpty) {
    return trimmed;
  }
  if (!trimmed.startsWith(_intervalSeparator)) {
    return null;
  }
  final String next = trimmed.substring(1).trim();
  if (next.isEmpty) {
    return null;
  }
  return next;
}

/// Reads [text], one interval with its brackets.
///
/// Returns the interval read, or why [text] is not one.
RangeReading _readInterval(String text) {
  final bool lowerInclusive = text.startsWith(_inclusiveLower);
  final bool upperInclusive = text.endsWith(_inclusiveUpper);
  final String inner = text.substring(1, text.length - 1);
  final List<String> bounds = inner.split(_boundSeparator);
  if (bounds.length == 1) {
    return _readExact(
      inner.trim(),
      bothInclusive: lowerInclusive && upperInclusive,
    );
  }
  if (bounds.length == 2) {
    return _readBounds(
      bounds[0].trim(),
      bounds[1].trim(),
      lowerInclusive: lowerInclusive,
      upperInclusive: upperInclusive,
    );
  }
  return const RangeRefused(_intervalShapeReason);
}

/// Reads [bound], the one bound of `[1.4.0]`, which only [bothInclusive]
/// brackets may enclose.
///
/// Returns the interval of exactly that version, or why it is not one.
RangeReading _readExact(String bound, {required bool bothInclusive}) {
  if (!bothInclusive) {
    return const RangeRefused(_intervalShapeReason);
  }
  final VersionReading reading = readVersion(bound, _shortestBound);
  return switch (reading) {
    VersionRead() => _exactly(SemanticVersion.fromReading(reading)),
    VersionRefused() => _boundRefusal(reading),
  };
}

/// The interval of exactly [version].
///
/// Returns the reading of that interval.
RangeReading _exactly(SemanticVersion version) => RangeRead(<VersionInterval>[
  ?bounded(
    lower: version,
    lowerInclusive: true,
    upper: version,
    upperInclusive: true,
  ),
]);

/// Reads the bounds [lower] and [upper], either of them empty for none,
/// held by the interval as [lowerInclusive] and [upperInclusive] say.
///
/// Returns the interval read, or why it is not one.
RangeReading _readBounds(
  String lower,
  String upper, {
  required bool lowerInclusive,
  required bool upperInclusive,
}) {
  final bool lowerMissing = lower.isEmpty;
  final bool upperMissing = upper.isEmpty;
  if (lowerMissing && lowerInclusive) {
    return const RangeRefused(_intervalShapeReason);
  }
  if (upperMissing && upperInclusive) {
    return const RangeRefused(_intervalShapeReason);
  }

  final VersionReading? from = lowerMissing
      ? null
      : readVersion(lower, _shortestBound);
  if (from is VersionRefused) {
    return _boundRefusal(from);
  }
  final VersionReading? to = upperMissing
      ? null
      : readVersion(upper, _shortestBound);
  if (to is VersionRefused) {
    return _boundRefusal(to);
  }

  final VersionInterval? interval = bounded(
    lower: _versionOf(from),
    lowerInclusive: lowerInclusive,
    upper: _versionOf(to),
    upperInclusive: upperInclusive,
  );
  if (interval == null) {
    return const RangeRefused(_intervalEmptyReason);
  }
  return RangeRead(<VersionInterval>[interval]);
}

/// The version [reading] read.
///
/// Returns the version, or `null` when there was no bound to read.
SemanticVersion? _versionOf(VersionReading? reading) =>
    reading is VersionRead ? SemanticVersion.fromReading(reading) : null;

/// The refusal of a bound that [reading] refused.
///
/// Returns the refusal.
RangeReading _boundRefusal(VersionRefused reading) =>
    RangeRefused('$_intervalBoundReason ${reading.reason}');
