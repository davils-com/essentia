/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';
import 'package:essentia/testing.dart';
import 'package:test/test.dart';

import 'ready_clause.dart';

/// Covers the contract between a select and its clauses: a handle handed
/// to a select that is over is disposed at once.
void main() {
  test(
    'a handle handed to a select that is over is disposed at once',
    () => runTest((it) async {
      final clause = ReadyClause(3);

      final int value = await select<int>(
        (it) => it.invoke(clause, (value) => value),
      );

      expect(value, 3);
      expect(clause.disposals, 1);
    }),
  );
}
