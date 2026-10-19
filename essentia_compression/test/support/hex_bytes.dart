/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:typed_data';

/// The bytes a string of hexadecimal digits spells, for test vectors.
extension HexBytes on String {
  /// The bytes of this string, two hexadecimal digits each.
  ///
  /// Returns them.
  Uint8List hexToByteArray() => Uint8List.fromList(<int>[
    for (var index = 0; index < length; index += 2)
      int.parse(substring(index, index + 2), radix: 16),
  ]);
}
