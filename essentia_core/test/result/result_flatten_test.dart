/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/result/result.dart';
import 'package:essentia_core/src/result/result_flatten.dart';
import 'package:test/test.dart';

/// The error the failures of these tests carry.
const _bad = FormatException('bad');

/// Covers [ResultFlatten], which collapses a result that carries a result.
void main() {
  test('collapses a success that carries a success', () {
    const Result<Result<int>> nested = Success<Result<int>>(Success<int>(7));

    final Result<int> flattened = nested.flatten();

    expect(flattened, const Success<int>(7));
  });

  test('collapses a success that carries a failure', () {
    const Result<Result<int>> nested = Success<Result<int>>(Failure<int>(_bad));

    final Result<int> flattened = nested.flatten();

    expect(flattened.errorOrNull, same(_bad));
  });

  test('collapses an outer failure into a failure', () {
    const Result<Result<int>> nested = Failure<Result<int>>(_bad);

    final Result<int> flattened = nested.flatten();

    expect(flattened.errorOrNull, same(_bad));
  });
}
