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

import 'package:essentia_core/src/bytes/hex_format.dart';
import 'package:meta/meta.dart';

/// The lowercase digits, in the order of their value.
const _lowerDigits = '0123456789abcdef';

/// The uppercase digits, in the order of their value.
const _upperDigits = '0123456789ABCDEF';

/// Writes any list of bytes as hexadecimal digits.
extension ByteListHex on List<int> {
  /// Writes the bytes as hexadecimal digits in [format].
  ///
  /// Every element is read as a byte, so only its low eight bits count.
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
