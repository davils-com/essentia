/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/bytes/hex_format.dart';
import 'package:meta/meta.dart';

/// The lowercase digits, in the order of their value.
const _lowerDigits = '0123456789abcdef';

/// The uppercase digits, in the order of their value.
const _upperDigits = '0123456789ABCDEF';

/// Kotlin's `ByteArray.toHexString` on any list of bytes.
extension ByteListHex on List<int> {
  /// Writes the bytes as hexadecimal digits in [format].
  ///
  /// Every element is read as a byte, so only its low eight bits count.
  /// Kotlin's `ByteArray.toHexString`.
  ///
  /// Returns the text, empty for no bytes.
  @useResult
  String toHexString([HexFormat format = HexFormat.defaultFormat]) {
    final String digits = format.upperCase ? _upperDigits : _lowerDigits;
    final text = StringBuffer();
    for (var index = 0; index < length; index++) {
      if (index > 0) {
        text.write(format.byteSeparator);
      }
      final int byte = this[index] & 0xff;
      text
        ..write(format.bytePrefix)
        ..write(digits[byte ~/ 16])
        ..write(digits[byte % 16])
        ..write(format.byteSuffix);
    }
    return text.toString();
  }
}
