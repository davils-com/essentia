/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/time/instant.dart';
import 'package:essentia/src/time/utc_offset.dart';
import 'package:meta/meta.dart';

/// A moment at which the clocks of a time zone are put forward or back,
/// from [offsetBefore] to [offsetAfter].
@immutable
final class ZoneTransition {
  /// The shift at [instant] from [offsetBefore] to [offsetAfter].
  const ZoneTransition(this.instant, this.offsetBefore, this.offsetAfter);

  /// The moment of the shift, the first that has [offsetAfter].
  final Instant instant;

  /// The offset up to the shift.
  final UtcOffset offsetBefore;

  /// The offset from the shift on.
  final UtcOffset offsetAfter;

  /// Whether the clocks are put forward and skip local times, as in
  /// spring.
  bool get isGap => offsetAfter.totalSeconds > offsetBefore.totalSeconds;

  /// Whether the clocks are put back and pass local times twice, as in
  /// autumn.
  bool get isOverlap => offsetAfter.totalSeconds < offsetBefore.totalSeconds;

  /// How far the clocks move, positive forward.
  Duration get shift =>
      Duration(seconds: offsetAfter.totalSeconds - offsetBefore.totalSeconds);

  /// Whether [other] is the same shift.
  @override
  bool operator ==(Object other) =>
      other is ZoneTransition &&
      other.instant == instant &&
      other.offsetBefore == offsetBefore &&
      other.offsetAfter == offsetAfter;

  /// A hash of the shift.
  @override
  int get hashCode => Object.hash(instant, offsetBefore, offsetAfter);

  /// Describes the shift, such as `2026-03-29T01:00:00Z +01:00 -> +02:00`.
  @override
  String toString() => '$instant $offsetBefore -> $offsetAfter';
}
