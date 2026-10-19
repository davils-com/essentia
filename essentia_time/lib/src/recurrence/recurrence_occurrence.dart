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
import 'package:essentia_time/src/zone/time_zone.dart';
import 'package:meta/meta.dart';

/// One repetition of a `RecurrenceSet`: the [local] date and time it
/// starts at and, for a zoned recurrence, the [instant].
@immutable
final class RecurrenceOccurrence implements Comparable<RecurrenceOccurrence> {
  /// The repetition at [local], at [instant] when zoned.
  const RecurrenceOccurrence(this.local, [this.instant]);

  /// The local date and time of the repetition.
  final LocalDateTime local;

  /// The moment of the repetition, or `null` when it floats.
  final Instant? instant;

  /// The date of the repetition.
  LocalDate get date => local.date;

  /// The moment of the repetition, a floating one read in [zone].
  Instant instantIn(TimeZone zone) => instant ?? zone.toInstant(local);

  /// Orders repetitions by their local time.
  @override
  int compareTo(RecurrenceOccurrence other) => local.compareTo(other.local);

  /// Whether [other] is the same repetition.
  @override
  bool operator ==(Object other) =>
      other is RecurrenceOccurrence &&
      other.local == local &&
      other.instant == instant;

  /// A hash of the repetition.
  @override
  int get hashCode => Object.hash(local, instant);

  /// Describes the repetition.
  @override
  String toString() => instant == null ? local.toString() : '$local ($instant)';
}
