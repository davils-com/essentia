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

import 'package:essentia_core/src/duration/duration_parsing.dart';

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

/// Reads text as a duration in either of two forms: the readable one
/// `Duration.toReadableString` writes, and ISO-8601.
///
/// ```dart
/// final Duration timeout = '1h 30m'.toDuration();
/// final Duration iso = 'PT1H30M'.toDuration();
/// final Duration? none = 'soon'.toDurationOrNull(); // null
/// ```
///
/// The readable form is a list of components of a number and a unit, `d`,
/// `h`, `m`, `s`, `ms`, `us` or `ns`, each unit at most once and largest
/// first, such as `30s`, `1h 30m` or `1.5ms`. A negative duration has a
/// leading `-`, and one of several components may be wrapped in
/// parentheses, `-(1h 30m)`. Fractions finer than a microsecond are rounded
/// to the nearest microsecond.
extension DurationText on String {
  /// Reads this text, such as `30s`, `1h 30m`, `-(2m 5s)` or `PT30S`, as a
  /// duration.
  ///
  /// Returns the duration.
  ///
  /// Throws a [FormatException] if the text is neither form. The message
  /// does not quote the text.
  Duration toDuration() =>
      toDurationOrNull() ?? (throw const FormatException('not a duration'));

  /// Reads this text as a duration, or answers `null` when it is neither
  /// the readable form nor ISO-8601.
  ///
  /// Returns the duration, or `null`.
  Duration? toDurationOrNull() {
    final String text = trim();
    final bool negative = text.startsWith('-');
    final String body = _unwrapped(
      negative ? text.substring(1).trim() : text,
      negative: negative,
    );
    if (body.startsWith('-')) {
      return null;
    }
    final Duration? duration = body.toIsoDurationOrNull() ?? _readable(body);
    if (duration == null) {
      return null;
    }
    return negative ? -duration : duration;
  }
}

/// Removes the parentheses that may wrap a negative duration of several
/// components.
///
/// Returns [body] without them, or [body] unchanged when it is not wrapped
/// or the duration is not [negative].
String _unwrapped(String body, {required bool negative}) {
  final bool wrapped = body.startsWith('(') && body.endsWith(')');
  if (!negative || !wrapped) {
    return body;
  }
  return body.substring(1, body.length - 1).trim();
}

/// Reads [text] as components of a number and a unit, each unit at most
/// once and largest first.
///
/// Returns the duration, or `null` when it is not that form.
Duration? _readable(String text) {
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
  return Duration(microseconds: total.round());
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
