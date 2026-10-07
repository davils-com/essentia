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

/// Covers time marks: elapsed time, arithmetic, ordering and the refusal
/// to mix the marks of two sources.
void main() {
  test('tells how much time has passed since it was made', () {
    final time = TestTimeSource();
    final TimeMark start = time.markNow();

    time.advance(3.seconds);

    expect(start.elapsedNow(), 3.seconds);
  });

  test('lies in the future after adding a duration', () {
    final time = TestTimeSource();
    final TimeMark deadline = time.markNow() + 5.seconds;

    time.advance(2.seconds);

    expect(deadline.elapsedNow(), -3.seconds);
    expect(deadline.hasPassedNow(), isFalse);
    expect(deadline.hasNotPassedNow(), isTrue);
  });

  test('has passed once the reading reaches it exactly', () {
    final time = TestTimeSource();
    final TimeMark deadline = time.markNow() + 5.seconds;

    time.advance(5.seconds);

    expect(deadline.hasPassedNow(), isTrue);
    expect(deadline.hasNotPassedNow(), isFalse);
  });

  test('moves back by a subtracted duration', () {
    final time = TestTimeSource()..advance(10.seconds);

    final TimeMark earlier = time.markNow() - 4.seconds;

    expect(earlier.reading, 6.seconds);
    expect(earlier.elapsedNow(), 4.seconds);
  });

  test('measures the difference to an earlier mark of the same source', () {
    final time = TestTimeSource();
    final TimeMark first = time.markNow();
    time.advance(7.seconds);
    final TimeMark second = time.markNow();

    expect(second.difference(first), 7.seconds);
    expect(first.difference(second), -7.seconds);
  });

  test('orders marks of the same source earlier first', () {
    final time = TestTimeSource();
    final TimeMark first = time.markNow();
    time.advance(1.seconds);
    final TimeMark second = time.markNow();

    final marks = <TimeMark>[second, first]..sort();

    expect(marks, <TimeMark>[first, second]);
    expect(first.compareTo(first), 0);
  });

  test('refuses to compare or subtract the marks of two sources', () {
    final TimeMark one = TestTimeSource().markNow();
    final TimeMark other = TestTimeSource().markNow();

    expect(() => one.compareTo(other), throwsArgumentError);
    expect(() => one.difference(other), throwsArgumentError);
  });

  test('is equal to a mark of the same source and reading only', () {
    final time = TestTimeSource();
    final TimeMark mark = time.markNow();

    expect(mark, TimeMark(time, Duration.zero));
    expect(mark.hashCode, TimeMark(time, Duration.zero).hashCode);
    expect(mark, isNot(TimeMark(TestTimeSource(), Duration.zero)));
    expect(mark, isNot(TimeMark(time, 1.seconds)));
  });

  test('renders its reading and its source', () {
    final time = TestTimeSource();

    expect(
      time.markNow().toString(),
      'TimeMark(0:00:00.000000 of TestTimeSource(0:00:00.000000))',
    );
  });
}
