/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// The ISO-8601 form, with days, hours, minutes and seconds.
final _isoDuration = RegExp(
  r'^P(?:(\d+(?:\.\d+)?)D)?(?:T(?:(\d+(?:\.\d+)?)H)?(?:(\d+(?:\.\d+)?)M)?'
  r'(?:(\d+(?:\.\d+)?)S)?)?$',
  caseSensitive: false,
);

/// The microseconds of a day, an hour, a minute and a second, in the order
/// of the groups of [_isoDuration].
const _isoUnits = <int>[
  Duration.microsecondsPerDay,
  Duration.microsecondsPerHour,
  Duration.microsecondsPerMinute,
  Duration.microsecondsPerSecond,
];

/// Reads text as an ISO-8601 duration, the counterpart of
/// `Duration.toIsoString`. Kotlin's `Duration.parseIsoString`.
///
/// ```dart
/// final Duration timeout = 'PT1H30M'.toIsoDuration();
/// final Duration? none = 'soon'.toIsoDurationOrNull(); // null
/// ```
///
/// The form is `P[nD][T[nH][nM][nS]]`, with an optional leading `-`, and
/// any component may carry a decimal fraction. Years, months and weeks are
/// refused: they have no fixed length, and a [Duration] does. Fractions
/// finer than a microsecond are rounded to the nearest microsecond.
extension DurationParsing on String {
  /// Reads this text, such as `PT30S`, `P1DT2H` or `-PT0.5S`, as an
  /// ISO-8601 duration.
  ///
  /// Returns the duration.
  ///
  /// Throws a [FormatException] if the text is not an ISO-8601 duration.
  /// The message does not quote the text.
  Duration toIsoDuration() =>
      toIsoDurationOrNull() ??
      (throw const FormatException('not an ISO 8601 duration'));

  /// Reads this text as an ISO-8601 duration, or answers `null` when it is
  /// not one.
  ///
  /// Returns the duration, or `null`.
  Duration? toIsoDurationOrNull() {
    final bool negative = startsWith('-');
    final String body = negative ? substring(1) : this;
    final RegExpMatch? match = _isoDuration.firstMatch(body);
    if (match == null) {
      return null;
    }
    final parts = <String?>[
      match.group(1),
      match.group(2),
      match.group(3),
      match.group(4),
    ];
    final bool hasTime = body.toUpperCase().contains('T');
    final bool timeIsEmpty =
        hasTime && parts.skip(1).every((part) => part == null);
    if (parts.every((part) => part == null) || timeIsEmpty) {
      return null;
    }
    var microseconds = 0.0;
    for (var index = 0; index < parts.length; index++) {
      final String? part = parts[index];
      if (part != null) {
        microseconds += double.parse(part) * _isoUnits[index];
      }
    }
    final duration = Duration(microseconds: microseconds.round());
    return negative ? -duration : duration;
  }
}
