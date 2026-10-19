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

import 'package:essentia_core/src/bytes/byte_list_content.dart';
import 'package:test/test.dart';

/// Covers comparing and hashing lists of bytes by their content.
void main() {
  test('equal content is equal', () {
    expect(<int>[1, 2, 3].contentEquals(<int>[1, 2, 3]), isTrue);
  });

  test('a different element, length or null is not equal', () {
    expect(<int>[1, 2, 3].contentEquals(<int>[1, 2, 4]), isFalse);
    expect(<int>[1, 2, 3].contentEquals(<int>[1, 2]), isFalse);
    expect(<int>[1].contentEquals(null), isFalse);
  });

  test('equal content shares a hash code', () {
    expect(
      <int>[9, 8].contentHashCode(),
      <int>[9, 8].toList().contentHashCode(),
    );
  });
}
