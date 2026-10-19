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

import 'package:essentia_core/src/collection/iterable_joining.dart';
import 'package:essentia_core/src/collection/join_format.dart';
import 'package:test/test.dart';

/// Four numbers to join.
const _numbers = <int>[1, 2, 3, 4];

/// Covers `joinToString`.
void main() {
  test('joins with a comma and a space by default', () {
    final String joined = _numbers.joinToString();

    expect(joined, '1, 2, 3, 4');
  });

  test('joins with a separator, a prefix and a postfix', () {
    final String joined = _numbers.joinToString(
      const JoinFormat(separator: '|', prefix: '<', postfix: '>'),
    );

    expect(joined, '<1|2|3|4>');
  });

  test('truncates after the limit with the marker', () {
    final String joined = _numbers.joinToString(
      const JoinFormat(limit: 2, truncated: '…'),
    );

    expect(joined, '1, 2, …');
  });

  test('does not truncate when the limit covers every element', () {
    final String joined = _numbers.joinToString(const JoinFormat(limit: 4));

    expect(joined, '1, 2, 3, 4');
  });

  test('joins an empty source into the prefix and postfix only', () {
    const empty = <int>[];

    final String joined = empty.joinToString(
      const JoinFormat(prefix: '[', postfix: ']'),
    );

    expect(joined, '[]');
  });
}
