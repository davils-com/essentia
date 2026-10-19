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

import 'package:essentia_time/essentia_time.dart';
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
