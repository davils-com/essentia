/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/result/result.dart';
import 'package:essentia/src/result/result_future.dart';
import 'package:test/test.dart';

/// The error the failures of these tests carry.
const _bad = FormatException('bad');

/// Covers [ResultFuture], which captures the outcome of a future.
void main() {
  test('turns a future that completes with a value into a success', () async {
    final future = Future<int>.value(7);

    final Result<int> result = await future.toResult();

    expect(result, const Success<int>(7));
  });

  test('turns a future that completes with an error into a failure', () async {
    final future = Future<int>.error(_bad, StackTrace.empty);

    final Result<int> result = await future.toResult();

    expect(result.errorOrNull, same(_bad));
  });

  test(
    'keeps the stack trace of a future that completed with an error',
    () async {
      final future = Future<int>.error(_bad, StackTrace.current);

      final Result<int> result = await future.toResult();

      expect(result.stackTraceOrNull, isNot(StackTrace.empty));
    },
  );
}
