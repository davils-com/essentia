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

import 'package:essentia_core/essentia_core.dart';
import 'package:essentia_time/testing.dart';
import 'package:test/test.dart';

/// Covers the time source a test moves by hand.
void main() {
  test('starts at zero', () {
    expect(TestTimeSource().read(), Duration.zero);
  });

  test('moves on by exactly what it is advanced by', () {
    final time = TestTimeSource()
      ..advance(2.seconds)
      ..advance(500.milliseconds);

    expect(time.read(), 2500.milliseconds);
  });

  test('accepts a zero advance', () {
    final time = TestTimeSource()..advance(Duration.zero);

    expect(time.read(), Duration.zero);
  });

  test('refuses to go backwards', () {
    final time = TestTimeSource();

    expect(() => time.advance(-1.seconds), throwsArgumentError);
    expect(time.read(), Duration.zero);
  });

  test('renders its reading', () {
    expect(
      (TestTimeSource()..advance(1.seconds)).toString(),
      'TestTimeSource(0:00:01.000000)',
    );
  });
}
