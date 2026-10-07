/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';
import 'package:test/test.dart';

/// Covers the clock of the system.
void main() {
  test('reads the current time in UTC', () {
    final DateTime before = DateTime.now().toUtc();

    final DateTime now = Clock.system.now();

    final DateTime after = DateTime.now().toUtc();
    expect(now.isUtc, isTrue);
    expect(now.isBefore(before), isFalse);
    expect(now.isAfter(after), isFalse);
  });

  test('names itself', () {
    expect(Clock.system.toString(), 'Clock(system)');
  });
}
