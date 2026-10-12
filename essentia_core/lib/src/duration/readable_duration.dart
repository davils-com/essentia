/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

/// Trailing zeros of the digits of a fraction.
final _trailingZeros = RegExp(r'0+$');

/// Kotlin's `Duration.toString()`: the readable form `String.toDuration`
/// reads back.
extension ReadableDuration on Duration {
  /// Renders the duration the way Kotlin's `Duration.toString()` does, such
  /// as `1h 30m`, `1d 0h 0m 5s`, `2.5s`, `1.5ms`, `250us` or `-(1m 30s)`.
  ///
  /// A duration of a second or more is written as days, hours, minutes and
  /// seconds; the components between the first and the last one that are
  /// not zero are written too. The seconds carry the fraction of a second.
  /// A shorter duration is written in milliseconds with a fraction, or in
  /// whole microseconds. Zero is `0s`. A negative duration gets a leading
  /// `-`, and the components are wrapped in parentheses when there are
  /// several.
  ///
  /// Returns the readable text.
  @useResult
  String toReadableString() {
    if (this == Duration.zero) {
      return '0s';
    }
    final Duration length = abs();
    final List<String> components = length < const Duration(seconds: 1)
        ? <String>[_belowASecond(length.inMicroseconds)]
        : _componentsOf(length);
    final String joined = components.join(' ');
    if (!isNegative) {
      return joined;
    }
    if (components.length == 1) {
      return '-$joined';
    }
    return '-($joined)';
  }
}

/// Splits [length], at least a second, into its readable components.
///
/// Returns the components, from days down to seconds.
List<String> _componentsOf(Duration length) {
  final int days = length.inDays;
  final int hours = length.inHours.remainder(Duration.hoursPerDay);
  final int minutes = length.inMinutes.remainder(Duration.minutesPerHour);
  final int seconds = length.inSeconds.remainder(Duration.secondsPerMinute);
  final int fraction = length.inMicroseconds.remainder(
    Duration.microsecondsPerSecond,
  );
  final hasDays = days != 0;
  final hasHours = hours != 0;
  final hasMinutes = minutes != 0;
  final bool hasSeconds = seconds != 0 || fraction != 0;
  return <String>[
    if (hasDays) '${days}d',
    if (hasHours || (hasDays && (hasMinutes || hasSeconds))) '${hours}h',
    if (hasMinutes || (hasSeconds && (hasHours || hasDays))) '${minutes}m',
    if (hasSeconds) '$seconds${_fractionOf(fraction, 6)}s',
  ];
}

/// Renders [microseconds], less than a second, in milliseconds or in
/// microseconds.
///
/// Returns the single component.
String _belowASecond(int microseconds) {
  if (microseconds < Duration.microsecondsPerMillisecond) {
    return '${microseconds}us';
  }
  final int milliseconds = microseconds ~/ Duration.microsecondsPerMillisecond;
  final int rest = microseconds.remainder(Duration.microsecondsPerMillisecond);
  return '$milliseconds${_fractionOf(rest, 3)}ms';
}

/// Renders [value] as a fraction of [digits] digits, without trailing
/// zeros.
///
/// Returns the fraction with its leading `.`, or empty text for zero.
String _fractionOf(int value, int digits) {
  if (value == 0) {
    return '';
  }
  final String text = value
      .toString()
      .padLeft(digits, '0')
      .replaceFirst(_trailingZeros, '');
  return '.$text';
}
