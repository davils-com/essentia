/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

@TestOn('browser')
library;

import 'package:essentia/src/time/current_time_zone_web.dart';
import 'package:test/test.dart';

/// Covers how the zone of the browser is read.
void main() {
  test('asks the browser for the name of its zone', () {
    expect(systemTimeZoneId(), isNotEmpty);
  });
}
