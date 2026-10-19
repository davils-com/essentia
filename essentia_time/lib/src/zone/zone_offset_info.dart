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

import 'package:essentia_time/src/zone/utc_offset.dart';
import 'package:essentia_time/src/zone/zone_transition.dart';
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
