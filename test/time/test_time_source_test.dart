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

/// Covers the time source a test moves by hand.
void main() {
  test('starts at zero', () {
    expect(TestTimeSource().read(), Duration.zero);
  });

  test('moves on by exactly what it is advanced by', () {
    final time = TestTimeSource()
      ..advance(2.seconds)
      ..advance(500.milliseconds);

    expect(time.read(), 2500.milliseconds);
  });

  test('accepts a zero advance', () {
    final time = TestTimeSource()..advance(Duration.zero);

    expect(time.read(), Duration.zero);
  });

  test('refuses to go backwards', () {
    final time = TestTimeSource();

    expect(() => time.advance(-1.seconds), throwsArgumentError);
    expect(time.read(), Duration.zero);
  });

  test('renders its reading', () {
    expect(
      (TestTimeSource()..advance(1.seconds)).toString(),
      'TestTimeSource(0:00:01.000000)',
    );
  });
}
