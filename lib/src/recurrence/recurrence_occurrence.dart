/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/time/instant.dart';
import 'package:essentia/src/time/local_date.dart';
import 'package:essentia/src/time/local_date_time.dart';
import 'package:essentia/src/time/time_zone.dart';
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
