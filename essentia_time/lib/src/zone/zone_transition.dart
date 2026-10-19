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

import 'package:essentia_time/src/instant.dart';
import 'package:essentia_time/src/zone/utc_offset.dart';
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
