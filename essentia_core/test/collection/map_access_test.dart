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

import 'package:essentia_core/src/collection/map_access.dart';
import 'package:test/test.dart';

/// Ports by protocol, one of them stored as `null`.
const _ports = <String, int?>{'http': 80, 'none': null};

/// Covers reading the values of a map by key.
void main() {
  test('reads the value of a present key', () {
    final int? port = _ports.getOrElse('http', () => 0);

    expect(port, 80);
  });

  test('keeps an absent value stored under a present key', () {
    final int? port = _ports.getOrElse('none', () => 0);

    expect(port, isNull);
  });

  test('falls back for a missing key', () {
    final int? port = _ports.getOrElse('ftp', () => 21);

    expect(port, 21);
  });

  test('reads the value of a key that must exist', () {
    final int? port = _ports.getValue('http');

    expect(port, 80);
  });

  test('refuses a key that is missing', () {
    int? read() => _ports.getValue('ftp');

    expect(read, throwsStateError);
  });
}
