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

import 'package:essentia_core/src/charset/internal/byte_decoding.dart';
import 'package:essentia_core/src/charset/internal/windows1252_table.dart';
import 'package:meta/meta.dart';

/// Decodes windows-1252, one byte to one character; a value that is no
/// byte decodes to U+FFFD.
@internal
final class Windows1252Decoding implements ByteDecoding {
  /// Creates the state of one decoding.
  Windows1252Decoding();

  /// Decodes the bytes of [chunk] from [start] to [end].
  ///
  /// Returns the text.
  @override
  String add(List<int> chunk, int start, int end) {
    final codes = <int>[
      for (int index = start; index < end; index++) _decode(chunk[index]),
    ];
    return String.fromCharCodes(codes);
  }

  /// Ends the decoding, which keeps no bytes.
  ///
  /// Returns the empty text.
  @override
  String close() => '';

  /// The character of [byte].
  ///
  /// Returns its code point.
  static int _decode(int byte) {
    if (byte < 0 || byte > 0xFF) {
      return 0xFFFD;
    }
    if (byte >= 0x80 && byte < 0xA0) {
      return windows1252High[byte - 0x80];
    }
    return byte;
  }
}
