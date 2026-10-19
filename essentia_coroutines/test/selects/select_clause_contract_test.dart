/*
 * Copyright 2026 Davils
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:essentia_coroutines/testing.dart';
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
