/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/icalendar/ics_time_zone.dart';
import 'package:essentia/src/time/time_zone.dart';

/// Finds the time zone a `TZID` of an iCalendar file names, and remembers
/// what it found.
///
/// It tries, in order: an identifier of the time zone database such as
/// `Europe/Berlin`; the `VTIMEZONE` of the file, as RFC 5545 asks, which
/// also covers names such as `W. Europe Standard Time`; and the database
/// identifier at the end of a path such as `/example.org/2026/Europe/Berlin`.
/// A name none of them knows is `null`, and its times float.
final class IcsZoneResolver {
  /// The resolver of the zones [timeZones] describe and of the database.
  IcsZoneResolver(List<IcsTimeZone> timeZones)
    : _described = <String, IcsTimeZone>{
        for (final IcsTimeZone zone in timeZones) zone.id: zone,
      };

  /// The described zones by identifier.
  final Map<String, IcsTimeZone> _described;

  /// What each name resolved to.
  final _resolved = <String, TimeZone?>{};

  /// The zone [id] names, or `null`.
  TimeZone? call(String id) => _resolved.putIfAbsent(id, () => _resolve(id));

  /// The names that resolved to nothing so far.
  List<String> get unresolved => <String>[
    for (final MapEntry<String, TimeZone?> entry in _resolved.entries)
      if (entry.value == null) entry.key,
  ];

  /// Finds the zone [id] names.
  TimeZone? _resolve(String id) {
    final TimeZone? database = TimeZone.ofOrNull(id);
    if (database != null) {
      return database;
    }
    final IcsTimeZone? described = _described[id];
    if (described != null) {
      return TimeZone.fromRules(id, described.toZoneRules());
    }
    final List<String> segments = id
        .split('/')
        .where((it) => it.isNotEmpty)
        .toList();
    for (var take = 3; take >= 2; take -= 1) {
      if (segments.length < take) {
        continue;
      }
      final TimeZone? suffix = TimeZone.ofOrNull(
        segments.sublist(segments.length - take).join('/'),
      );
      if (suffix != null) {
        return suffix;
      }
    }
    return null;
  }
}
