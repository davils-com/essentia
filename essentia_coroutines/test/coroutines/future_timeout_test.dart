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

import 'dart:async';

import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:essentia_coroutines/testing.dart';
import 'package:test/test.dart';

/// How long the tests wait for a future.
const _limit = Duration(milliseconds: 20);

/// Covers waiting for a plain future for a limited time, on virtual time.
void main() {
  test(
    'passes on a value that arrives in time',
    () => runTest((it) async {
      final answer = Future<int>.value(42);

      final int? value = await answer.timeoutOrNull(_limit);

      expect(value, 42);
    }),
  );

  test(
    'gives up with nothing when the value arrives too late',
    () => runTest((it) async {
      final Future<int> never = Completer<int>().future;

      final int? value = await never.timeoutOrNull(_limit);

      expect(value, isNull);
      expect(it.currentTime, _limit);
    }),
  );

  test(
    'lets the late work run to its end after giving up',
    () => runTest((it) async {
      final log = <String>[];
      final work = Future<void>.delayed(_limit * 2, () => log.add('finished'));

      await work.timeoutOrNull(_limit);
      log.add('gave up');
      await work;

      expect(log, <String>['gave up', 'finished']);
    }),
  );

  test(
    'passes on an error that arrives in time',
    () => runTest((it) async {
      final failing = Future<int>.error(const FormatException());

      await expectLater(failing.timeoutOrNull(_limit), throwsFormatException);
    }),
  );
}
