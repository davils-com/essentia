/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/collection/nullable_map.dart';
import 'package:test/test.dart';

/// Covers treating a missing map as an empty one.
void main() {
  test('treats an absent map as empty', () {
    const Map<String, int>? absent = null;

    final bool empty = absent.isNullOrEmpty;

    expect(empty, isTrue);
  });

  test('treats a map with entries as not empty', () {
    const present = <String, int>{'ssh': 22};

    final bool empty = present.isNullOrEmpty;

    expect(empty, isFalse);
  });

  test('replaces an absent map with an empty one', () {
    const Map<String, int>? absent = null;

    final Map<String, int> ports = absent.orEmpty();

    expect(ports, isEmpty);
  });

  test('replaces an absent map with one that cannot be modified', () {
    const Map<String, int>? absent = null;
    final Map<String, int> ports = absent.orEmpty();

    void modify() => ports['ssh'] = 22;

    expect(modify, throwsUnsupportedError);
  });

  test('keeps a map that is present', () {
    const present = <String, int>{'ssh': 22};

    final Map<String, int> ports = present.orEmpty();

    expect(ports, present);
  });
}
