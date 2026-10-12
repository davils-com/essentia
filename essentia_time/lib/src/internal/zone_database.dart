/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_time/src/internal/tzdata.dart';
import 'package:essentia_time/src/internal/zone_data_codec.dart';
import 'package:essentia_time/src/zone/zone_rules.dart';
import 'package:meta/meta.dart';

/// The rules decoded so far, by canonical identifier.
final _decoded = <String, ZoneRules>{};

/// Every identifier of the database, links included, built on first use.
Set<String>? _ids;

/// The version of the built-in time zone database.
@internal
String get zoneDatabaseVersion => tzdataVersion;

/// The identifiers of every zone of the database, links included.
@internal
Set<String> zoneIds() => _ids ??= Set<String>.unmodifiable(<String>{
  ...tzdataZoneIds,
  ...tzdataLinkIds,
});

/// The rules of the zone [id] names, following a link, or `null` when the
/// database has no such zone.
@internal
ZoneRules? zoneRulesOf(String id) {
  int index = _indexIn(tzdataZoneIds, id);
  if (index < 0) {
    final int link = _indexIn(tzdataLinkIds, id);
    if (link < 0) {
      return null;
    }
    index = tzdataLinkTargets[link];
  }
  final String canonical = tzdataZoneIds[index];
  return _decoded[canonical] ??= decodeZone(tzdataZoneData[index].join());
}

/// The index of [id] in the sorted [ids], or -1.
int _indexIn(List<String> ids, String id) {
  var low = 0;
  int high = ids.length - 1;
  while (low <= high) {
    final int middle = (low + high) ~/ 2;
    final int order = ids[middle].compareTo(id);
    if (order == 0) {
      return middle;
    }
    if (order < 0) {
      low = middle + 1;
      continue;
    }
    high = middle - 1;
  }
  return -1;
}
