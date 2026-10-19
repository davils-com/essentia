/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:convert';

import 'package:essentia_core/src/bytes/byte_string.dart';
import 'package:essentia_core/src/bytes/hex_format.dart';
import 'package:essentia_core/src/bytes/hex_parsing.dart';
import 'package:meta/meta.dart';

/// Turns text into a [ByteString], from its UTF-8 encoding or from
/// hexadecimal digits.
extension StringToByteString on String {
  /// Encodes the text as UTF-8.
  ///
  /// Returns the byte string.
  @useResult
  ByteString encodeToByteString() => ByteString(utf8.encode(this));

  /// Reads the bytes [format] wrote.
  ///
  /// Returns the byte string.
  ///
  /// Throws a [FormatException] when the text is not in [format].
  @useResult
  ByteString hexToByteString([HexFormat format = HexFormat.defaultFormat]) =>
      ByteString(hexToByteArray(format));
}
