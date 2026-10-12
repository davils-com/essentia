/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
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
