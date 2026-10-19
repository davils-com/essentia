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

import 'package:essentia_core/src/collection/map_with_default.dart';
import 'package:test/test.dart';

/// Ports by protocol, defaulting to the length of a missing protocol.
final _ports = MapWithDefault<String, int>(const <String, int>{
  'ssh': 22,
}, (key) => key.length);

/// Covers the read only map view with a default for missing keys.
void main() {
  test('reads the value of a present key', () {
    final int port = _ports.getValue('ssh');

    expect(port, 22);
  });

  test('derives the value of a missing key from the default', () {
    final int port = _ports.getValue('https');

    expect(port, 5);
  });

  test('keeps plain lookups of missing keys absent', () {
    final int? port = _ports['https'];

    expect(port, isNull);
  });

  test('refuses to be modified', () {
    void modify() => _ports['ftp'] = 21;

    expect(modify, throwsUnsupportedError);
  });
}
