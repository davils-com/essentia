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

import 'package:essentia_core/src/collection/join_format.dart';
import 'package:test/test.dart';

/// Covers the limit of `JoinFormat`.
void main() {
  test('admits every element without a limit', () {
    const format = JoinFormat();

    final bool admitted = format.admits(1000);

    expect(admitted, isTrue);
  });

  test('admits the elements up to its limit', () {
    final format = JoinFormat(limit: int.parse('2'));

    final bool admitted = format.admits(2);

    expect(admitted, isTrue);
  });

  test('refuses the elements beyond its limit', () {
    const format = JoinFormat(limit: 2);

    final bool admitted = format.admits(3);

    expect(admitted, isFalse);
  });

  test('refuses a negative limit', () {
    JoinFormat build() => JoinFormat(limit: int.parse('-1'));

    expect(build, throwsA(isA<AssertionError>()));
  });
}
