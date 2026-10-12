/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:io';

import 'package:meta/meta.dart';

/// Reads the name of the time zone of this system: the `TZ` variable,
/// then the link `/etc/localtime`, then the file `/etc/timezone`.
///
/// Returns the name, or `null` when none of them tells it, as on Windows.
@internal
String? systemTimeZoneId() => systemTimeZoneIdFrom(
  environment: (name) => Platform.environment[name],
  linkTarget: (path) {
    try {
      return Link(path).targetSync();
    } on FileSystemException {
      return null;
    }
  },
  readFile: (path) {
    try {
      return File(path).readAsStringSync();
    } on FileSystemException {
      return null;
    }
  },
);

/// Reads the name of the time zone through [environment], [linkTarget]
/// and [readFile], in the order [systemTimeZoneId] tells.
///
/// Returns the name, or `null` when none of them tells it.
@internal
String? systemTimeZoneIdFrom({
  required String? Function(String name) environment,
  required String? Function(String path) linkTarget,
  required String? Function(String path) readFile,
}) {
  final String? variable = environment('TZ');
  if (variable != null && variable.isNotEmpty) {
    final String name = variable.startsWith(':')
        ? variable.substring(1)
        : variable;
    final String? fromPath = _zoneOfPath(name);
    if (fromPath != null) {
      return fromPath;
    }
    if (!name.startsWith('/')) {
      return name;
    }
  }
  final String? target = linkTarget('/etc/localtime');
  if (target != null) {
    final String? fromLink = _zoneOfPath(target);
    if (fromLink != null) {
      return fromLink;
    }
  }
  final String? file = readFile('/etc/timezone');
  if (file == null) {
    return null;
  }
  final String name = file.split('\n').first.trim();
  return name.isEmpty ? null : name;
}

/// The zone name in a path into a zone directory, such as `Europe/Berlin`
/// in `/usr/share/zoneinfo/Europe/Berlin`, or `null`.
String? _zoneOfPath(String path) {
  const marker = 'zoneinfo/';
  final int at = path.lastIndexOf(marker);
  if (at < 0) {
    return null;
  }
  String name = path.substring(at + marker.length);
  for (final prefix in <String>['posix/', 'right/']) {
    if (name.startsWith(prefix)) {
      name = name.substring(prefix.length);
    }
  }
  return name.isEmpty ? null : name;
}
