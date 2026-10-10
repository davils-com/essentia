/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

@TestOn('vm')
library;

import 'package:essentia/src/time/current_time_zone_io.dart';
import 'package:test/test.dart';

/// Reads the zone of the system through [environment], the link target
/// [link] and the file [file].
///
/// Returns the name it finds.
String? _read({
  Map<String, String> environment = const <String, String>{},
  String? link,
  String? file,
}) => systemTimeZoneIdFrom(
  environment: (name) => environment[name],
  linkTarget: (path) => path == '/etc/localtime' ? link : null,
  readFile: (path) => path == '/etc/timezone' ? file : null,
);

/// Covers how the zone of a system is read where `dart:io` is.
void main() {
  test('prefers the TZ variable, by name or by path', () {
    expect(
      _read(environment: <String, String>{'TZ': 'Europe/Berlin'}),
      'Europe/Berlin',
    );
    expect(
      _read(environment: <String, String>{'TZ': ':Asia/Tokyo'}),
      'Asia/Tokyo',
    );
    expect(
      _read(
        environment: <String, String>{'TZ': '/usr/share/zoneinfo/America/Lima'},
      ),
      'America/Lima',
    );
    expect(
      _read(
        environment: <String, String>{'TZ': '/etc/custom'},
        link: '/usr/share/zoneinfo/Europe/Rome',
      ),
      'Europe/Rome',
    );
  });

  test('follows the link of /etc/localtime', () {
    expect(_read(link: '/usr/share/zoneinfo/Europe/Paris'), 'Europe/Paris');
    expect(_read(link: '../usr/share/zoneinfo/posix/Asia/Seoul'), 'Asia/Seoul');
    expect(_read(link: '/var/db/timezone/zoneinfo/right/UTC'), 'UTC');
    expect(
      _read(link: '/usr/share/zoneinfo/', file: 'Europe/Oslo\n'),
      'Europe/Oslo',
    );
  });

  test('reads /etc/timezone last and gives up quietly', () {
    expect(
      _read(link: '/somewhere/else', file: 'Europe/Vienna\n'),
      'Europe/Vienna',
    );
    expect(_read(file: '\n'), isNull);
    expect(_read(), isNull);
    expect(_read(environment: <String, String>{'TZ': ''}), isNull);
  });

  test('reads this system without failing', () {
    expect(systemTimeZoneId, returnsNormally);
  });
}
