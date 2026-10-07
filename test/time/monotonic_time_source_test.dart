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

/// Covers the monotonic time source of the running program.
void main() {
  test('never reads less than before', () {
    final Duration first = TimeSource.monotonic.read();
    final Duration second = TimeSource.monotonic.read();

    expect(second, greaterThanOrEqualTo(first));
  });

  test('is one source for the whole program', () {
    expect(identical(TimeSource.monotonic, TimeSource.monotonic), isTrue);
  });

  test('marks a point that is never in the future', () {
    final TimeMark mark = TimeSource.monotonic.markNow();

    expect(mark.hasPassedNow(), isTrue);
    expect(mark.source, same(TimeSource.monotonic));
  });

  test('names itself', () {
    expect(TimeSource.monotonic.toString(), 'TimeSource(monotonic)');
  });
}
