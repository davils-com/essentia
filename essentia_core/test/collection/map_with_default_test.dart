/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
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
