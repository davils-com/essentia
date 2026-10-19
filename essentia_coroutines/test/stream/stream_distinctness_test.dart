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
import 'package:essentia_coroutines/src/stream/stream_distinctness.dart';
import 'package:test/test.dart';

/// Checks `distinctUntilChangedBy`.
void main() {
  test('drops consecutive elements with the same key', () async {
    final stream = Stream<String>.fromIterable(<String>['a', 'b', 'cc', 'd']);

    final List<String> distinct = await stream
        .distinctUntilChangedBy((word) => word.length)
        .toList();

    expect(distinct, <String>['a', 'cc', 'd']);
  });

  test('emits a key again once another key came between', () async {
    final stream = Stream<String>.fromIterable(<String>['a', 'bb', 'c']);

    final List<String> distinct = await stream
        .distinctUntilChangedBy((word) => word.length)
        .toList();

    expect(distinct, <String>['a', 'bb', 'c']);
  });
}
