/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia/src/async/future_timeout.dart';
import 'package:test/test.dart';

/// How long the tests wait for a future.
const _limit = Duration(milliseconds: 20);

/// Covers waiting for a future for a limited time.
void main() {
  test('passes on a value that arrives in time', () async {
    final answer = Future<int>.value(42);

    final int? value = await answer.timeoutOrNull(_limit);

    expect(value, 42);
  });

  test('gives up with nothing when the value arrives too late', () async {
    final Future<int> never = Completer<int>().future;

    final int? value = await never.timeoutOrNull(_limit);

    expect(value, isNull);
  });

  test('lets the late work run to its end after giving up', () async {
    final log = <String>[];
    final work = Future<void>.delayed(_limit * 2, () => log.add('finished'));

    await work.timeoutOrNull(_limit);
    log.add('gave up');
    await work;

    expect(log, <String>['gave up', 'finished']);
  });

  test('passes on an error that arrives in time', () async {
    final failing = Future<int>.error(const FormatException());

    Future<int?> wait() => failing.timeoutOrNull(_limit);

    await expectLater(wait, throwsFormatException);
  });
}
