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

import 'package:essentia_time/src/source/time_source.dart';
import 'package:meta/meta.dart';

/// A point in time of one [TimeSource].
///
/// A mark remembers the reading of its source when it was made, so it can
/// tell how much time has passed since then. Marks of the same source can be
/// compared and subtracted; marks of different sources cannot, because their
/// origins have nothing to do with each other.
///
/// ```dart
/// final TimeMark deadline = timeSource.markNow() + 5.seconds;
/// if (deadline.hasPassedNow()) {
///   throw TimeoutException('too late');
/// }
/// ```
@immutable
final class TimeMark implements Comparable<TimeMark> {
  /// Creates the mark of [source] at its [reading].
  const TimeMark(this.source, this.reading);

  /// The time source this mark belongs to.
  final TimeSource source;

  /// The reading of [source] this mark stands for.
  final Duration reading;

  /// How much time has passed since this mark.
  ///
  /// Returns a negative duration for a mark that lies in the future.
  Duration elapsedNow() => source.read() - reading;

  /// Whether the current reading of [source] has reached this mark.
  ///
  /// Returns `true` once no time is left until the mark.
  bool hasPassedNow() => !elapsedNow().isNegative;

  /// Whether the current reading of [source] has not reached this mark yet.
  ///
  /// Returns `true` while time is left until the mark.
  bool hasNotPassedNow() => elapsedNow().isNegative;

  /// The mark [duration] after this one.
  ///
  /// Returns a mark of the same source.
  TimeMark operator +(Duration duration) =>
      TimeMark(source, reading + duration);

  /// The mark [duration] before this one.
  ///
  /// Returns a mark of the same source.
  TimeMark operator -(Duration duration) =>
      TimeMark(source, reading - duration);

  /// How much later this mark lies than [other].
  ///
  /// Returns a negative duration when [other] lies later.
  ///
  /// Throws an [ArgumentError] if [other] belongs to another source.
  Duration difference(TimeMark other) {
    _requireSameSource(other);
    return reading - other.reading;
  }

  /// Orders this mark against [other] of the same source, earlier first.
  ///
  /// Returns a negative number, zero or a positive number.
  ///
  /// Throws an [ArgumentError] if [other] belongs to another source.
  @override
  int compareTo(TimeMark other) {
    _requireSameSource(other);
    return reading.compareTo(other.reading);
  }

  /// Two marks are equal when they belong to the same source and stand for
  /// the same reading.
  @override
  bool operator ==(Object other) =>
      other is TimeMark &&
      identical(source, other.source) &&
      reading == other.reading;

  /// The hash of the source and the reading.
  @override
  int get hashCode => Object.hash(identityHashCode(source), reading);

  /// Renders the reading and the source.
  @override
  String toString() => 'TimeMark($reading of $source)';

  /// Refuses [other] unless it belongs to the source of this mark.
  ///
  /// Throws an [ArgumentError] if it does not.
  void _requireSameSource(TimeMark other) {
    if (!identical(source, other.source)) {
      throw ArgumentError.value(
        other,
        'other',
        'Marks of different time sources cannot be compared',
      );
    }
  }
}
