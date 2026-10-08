/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:typed_data';

import 'package:essentia/src/bytes/hex_format.dart';
import 'package:meta/meta.dart';

/// The lowercase digits, in the order of their value.
const _lowerDigits = '0123456789abcdef';

/// Kotlin's `String.hexToByteArray` and `hexToByteString`.
extension HexParsing on String {
  /// Reads the bytes [format] wrote, digits in either case.
  ///
  /// Kotlin's `String.hexToByteArray`.
  ///
  /// Returns the bytes, empty for empty text.
  ///
  /// Throws a [FormatException] when the text is not in [format]. Its
  /// message names the offset of the first mistake and never quotes the
  /// text, which is routinely key material.
  @useResult
  Uint8List hexToByteArray([HexFormat format = HexFormat.defaultFormat]) {
    if (isEmpty) {
      return Uint8List(0);
    }
    final bytes = <int>[];
    var offset = 0;
    while (true) {
      offset = _expect(format.bytePrefix, offset);
      final int high = _digitAt(offset);
      final int low = _digitAt(offset + 1);
      bytes.add(high * 16 + low);
      offset = _expect(format.byteSuffix, offset + 2);
      if (offset == length) {
        return Uint8List.fromList(bytes);
      }
      offset = _expect(format.byteSeparator, offset);
    }
  }

  /// Checks that [piece] stands at [offset].
  ///
  /// Returns the offset after [piece].
  ///
  /// Throws a [FormatException] when it does not.
  int _expect(String piece, int offset) {
    if (!startsWith(piece, offset)) {
      throw FormatException('Not hexadecimal text of the format', null, offset);
    }
    return offset + piece.length;
  }

  /// Reads the digit at [offset].
  ///
  /// Returns its value.
  ///
  /// Throws a [FormatException] when there is no digit at [offset].
  int _digitAt(int offset) {
    if (offset >= length) {
      throw FormatException(
        'Hexadecimal text ends inside a byte',
        null,
        offset,
      );
    }
    final int value = _lowerDigits.indexOf(this[offset].toLowerCase());
    if (value < 0) {
      throw FormatException('Not a hexadecimal digit', null, offset);
    }
    return value;
  }
}
