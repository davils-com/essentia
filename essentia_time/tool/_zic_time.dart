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

part of 'generate_tzdata.dart';

/// A time of day in the database: seconds after midnight, which may be
/// negative or beyond a day, and the clock they are read on.
final class ZicTime {
  /// The time [seconds] after midnight on the clock [definition].
  const ZicTime(this.seconds, this.definition);

  /// Reads a time such as `2:00`, `1:00u`, `24:00`, `-0:25:21` or `-`,
  /// the wall clock unless a suffix says otherwise.
  ///
  /// Throws a [FormatException] for any other text.
  factory ZicTime.parse(String text) {
    if (text == '-') {
      return const ZicTime(0, ZoneTimeDefinition.wall);
    }
    final RegExpMatch? match = RegExp(
      r'^(-)?(\d+)(?::(\d+))?(?::(\d+))?([wsugzd])?$',
    ).firstMatch(text);
    if (match == null) {
      throw FormatException('Not a time', text);
    }
    final sign = match.group(1) == null ? 1 : -1;
    final int seconds =
        int.parse(match.group(2)!) * 3600 +
        int.parse(match.group(3) ?? '0') * 60 +
        int.parse(match.group(4) ?? '0');
    final String suffix = match.group(5) ?? 'w';
    if (suffix == 's') {
      return ZicTime(sign * seconds, ZoneTimeDefinition.standard);
    }
    if ('ugz'.contains(suffix)) {
      return ZicTime(sign * seconds, ZoneTimeDefinition.utc);
    }
    return ZicTime(sign * seconds, ZoneTimeDefinition.wall);
  }

  /// The seconds after midnight.
  final int seconds;

  /// The clock the time is read on.
  final ZoneTimeDefinition definition;

  /// The epoch second at which [localSeconds], a moment read on this
  /// clock, happens in a zone of [standardOffset] seconds that currently
  /// saves [save] seconds.
  static int toUtc(
    int localSeconds,
    ZoneTimeDefinition definition,
    int standardOffset,
    int save,
  ) => switch (definition) {
    ZoneTimeDefinition.utc => localSeconds,
    ZoneTimeDefinition.standard => localSeconds - standardOffset,
    ZoneTimeDefinition.wall => localSeconds - standardOffset - save,
  };
}
