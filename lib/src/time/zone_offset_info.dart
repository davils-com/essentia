/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/time/utc_offset.dart';
import 'package:essentia/src/time/zone_transition.dart';
import 'package:meta/meta.dart';

/// What a time zone makes of a local date and time: a [RegularOffsetInfo]
/// for one that exists once, a [GapOffsetInfo] for one the clocks skip and
/// an [OverlapOffsetInfo] for one they pass twice.
@immutable
sealed class ZoneOffsetInfo {
  /// Creates the information.
  const ZoneOffsetInfo();
}

/// A local time that exists exactly once, at [offset].
final class RegularOffsetInfo extends ZoneOffsetInfo {
  /// The local time at [offset].
  const RegularOffsetInfo(this.offset);

  /// The one offset of the local time.
  final UtcOffset offset;

  /// Whether [other] has the same offset.
  @override
  bool operator ==(Object other) =>
      other is RegularOffsetInfo && other.offset == offset;

  /// A hash of the offset.
  @override
  int get hashCode => offset.hashCode;

  /// Describes the information.
  @override
  String toString() => 'Regular($offset)';
}

/// A local time the clocks skip when they are put forward at [transition].
final class GapOffsetInfo extends ZoneOffsetInfo {
  /// The local time skipped by [transition].
  const GapOffsetInfo(this.transition);

  /// The shift that skips the local time.
  final ZoneTransition transition;

  /// Whether [other] is skipped by the same shift.
  @override
  bool operator ==(Object other) =>
      other is GapOffsetInfo && other.transition == transition;

  /// A hash of the shift.
  @override
  int get hashCode => transition.hashCode;

  /// Describes the information.
  @override
  String toString() => 'Gap($transition)';
}

/// A local time the clocks pass twice when they are put back at
/// [transition], once at each of its offsets.
final class OverlapOffsetInfo extends ZoneOffsetInfo {
  /// The local time repeated by [transition].
  const OverlapOffsetInfo(this.transition);

  /// The shift that repeats the local time.
  final ZoneTransition transition;

  /// Whether [other] is repeated by the same shift.
  @override
  bool operator ==(Object other) =>
      other is OverlapOffsetInfo && other.transition == transition;

  /// A hash of the shift.
  @override
  int get hashCode => transition.hashCode;

  /// Describes the information.
  @override
  String toString() => 'Overlap($transition)';
}
