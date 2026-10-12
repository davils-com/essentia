/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_time/src/internal/iso_text.dart';
import 'package:essentia_time/src/zone/time_zone.dart';
import 'package:meta/meta.dart';

/// The difference of a local time from UTC, Kotlin's
/// `kotlinx.datetime.UtcOffset`: `+02:00` in Berlin in summer.
///
/// It lies from -18:00 to +18:00 and is held as [totalSeconds].
@immutable
final class UtcOffset implements Comparable<UtcOffset> {
  /// The offset of [hours], [minutes] and [seconds], which all share one
  /// sign.
  ///
  /// Throws an [ArgumentError] for parts of mixed signs, minutes or seconds
  /// beyond 59, or an offset beyond 18 hours.
  factory UtcOffset({int hours = 0, int minutes = 0, int seconds = 0}) {
    final bool positive = hours > 0 || minutes > 0 || seconds > 0;
    final bool negative = hours < 0 || minutes < 0 || seconds < 0;
    if (positive && negative) {
      throw ArgumentError('The parts of an offset must share one sign');
    }
    if (minutes.abs() > 59 || seconds.abs() > 59) {
      throw ArgumentError('Minutes and seconds must lie within 59');
    }
    return UtcOffset.fromTotalSeconds(hours * 3600 + minutes * 60 + seconds);
  }

  /// The offset of [totalSeconds] seconds.
  ///
  /// Throws an [ArgumentError] beyond 18 hours either way.
  factory UtcOffset.fromTotalSeconds(int totalSeconds) {
    if (totalSeconds.abs() > _maxSeconds) {
      throw ArgumentError.value(
        totalSeconds,
        'totalSeconds',
        'Must lie within 18 hours',
      );
    }
    return UtcOffset._(totalSeconds);
  }

  /// Reads an offset as ISO 8601 writes it: `Z`, `+02`, `+0200`,
  /// `+02:00` or `+02:00:30`.
  ///
  /// Throws a [FormatException] for any other text.
  factory UtcOffset.parse(String text) {
    if (text == 'Z' || text == 'z') {
      return zero;
    }
    final RegExpMatch? match = _pattern.firstMatch(text);
    if (match == null) {
      throw FormatException('Not a UTC offset', text);
    }
    final sign = match.group(1) == '-' ? -1 : 1;
    final int hours = int.parse(match.group(2)!);
    final int minutes = int.parse(match.group(3) ?? match.group(5) ?? '0');
    final int seconds = int.parse(match.group(4) ?? match.group(6) ?? '0');
    final int total = hours * 3600 + minutes * 60 + seconds;
    if (minutes > 59 || seconds > 59 || total > _maxSeconds) {
      throw FormatException('Not a UTC offset', text);
    }
    return UtcOffset._(sign * total);
  }

  /// Creates the offset of valid seconds.
  const UtcOffset._(this.totalSeconds);

  /// The offset of UTC itself.
  static const zero = UtcOffset._(0);

  /// The largest offset in seconds, 18 hours.
  static const _maxSeconds = 64800;

  /// The text of an ISO 8601 offset.
  static final _pattern = RegExp(
    r'^([+-])(\d{2})(?:(?::(\d{2})(?::(\d{2}))?)|(?:(\d{2})(\d{2})?))?$',
  );

  /// The offset in seconds, positive east of Greenwich.
  final int totalSeconds;

  /// The time zone that always has this offset.
  FixedOffsetTimeZone asTimeZone() => FixedOffsetTimeZone(this);

  /// Orders offsets from west to east.
  @override
  int compareTo(UtcOffset other) => totalSeconds.compareTo(other.totalSeconds);

  /// Whether [other] is the same offset.
  @override
  bool operator ==(Object other) =>
      other is UtcOffset && other.totalSeconds == totalSeconds;

  /// A hash of the offset.
  @override
  int get hashCode => totalSeconds.hashCode;

  /// The offset as ISO 8601 writes it: `Z` for UTC, else `+02:00`, with
  /// seconds only when there are any.
  @override
  String toString() {
    if (totalSeconds == 0) {
      return 'Z';
    }
    final sign = totalSeconds < 0 ? '-' : '+';
    final int total = totalSeconds.abs();
    final head =
        '$sign${twoDigits(total ~/ 3600)}:${twoDigits(total ~/ 60 % 60)}';
    final int seconds = total % 60;
    if (seconds == 0) {
      return head;
    }
    return '$head:${twoDigits(seconds)}';
  }
}
