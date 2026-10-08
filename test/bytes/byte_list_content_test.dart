/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/bytes/byte_list_content.dart';
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
