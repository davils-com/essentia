/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/collection/map_defaulting.dart';
import 'package:essentia/src/collection/map_with_default.dart';
import 'package:test/test.dart';

/// Covers giving a map a default for missing keys.
void main() {
  test('wraps a map with a default for missing keys', () {
    const ports = <String, int>{'ssh': 22};

    final MapWithDefault<String, int> defaulted = ports.withDefault((_) => 0);

    expect(defaulted.getValue('ftp'), 0);
  });
}
