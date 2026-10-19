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
