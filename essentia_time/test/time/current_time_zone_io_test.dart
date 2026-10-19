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

@TestOn('vm')
library;

import 'package:essentia_time/src/zone/current_time_zone_io.dart';
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
