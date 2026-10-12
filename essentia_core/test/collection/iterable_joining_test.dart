/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/collection/iterable_joining.dart';
import 'package:essentia_core/src/collection/join_format.dart';
import 'package:test/test.dart';

/// Four numbers to join.
const _numbers = <int>[1, 2, 3, 4];

/// Covers Kotlin's `joinToString`.
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

  test('truncates after the limit the way Kotlin does', () {
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
