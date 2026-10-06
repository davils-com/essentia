/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/collection/map_query.dart';
import 'package:test/test.dart';

/// Ports by protocol.
const _ports = <String, int>{'http': 80, 'ssh': 22};

/// Covers asking questions about the entries of a map.
void main() {
  test('finds an entry that matches', () {
    final bool found = _ports.any((key, value) => value == 22);

    expect(found, isTrue);
  });

  test('finds no entry when none matches', () {
    final bool found = _ports.any((key, value) => value == 21);

    expect(found, isFalse);
  });

  test('confirms that every entry matches', () {
    final bool all = _ports.every((key, value) => value < 100);

    expect(all, isTrue);
  });

  test('denies that every entry matches', () {
    final bool all = _ports.every((key, value) => key.length > 3);

    expect(all, isFalse);
  });

  test('confirms that no entry matches', () {
    final bool nothing = _ports.none((key, value) => value > 1000);

    expect(nothing, isTrue);
  });

  test('counts the entries that match', () {
    final int count = _ports.countWhere((key, value) => key.length > 3);

    expect(count, 1);
  });
}
