/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/charset/internal/string_encoding.dart';
import 'package:essentia_core/src/charset/internal/windows1252_table.dart';
import 'package:meta/meta.dart';

/// Encodes windows-1252, one character to one byte.
@internal
final class Windows1252Encoding implements StringEncoding {
  /// Creates the state of one encoding.
  Windows1252Encoding();

  /// Encodes the code units of [chunk] from [start] to [end].
  ///
  /// Returns the bytes.
  ///
  /// Throws an [ArgumentError] for a character windows-1252 cannot
  /// represent.
  @override
  List<int> add(String chunk, int start, int end) => <int>[
    for (int index = start; index < end; index++)
      _encode(chunk.codeUnitAt(index), index),
  ];

  /// Ends the encoding, which keeps no code units.
  ///
  /// Returns no bytes.
  @override
  List<int> close() => const <int>[];

  /// The byte of the character [code] at [index].
  ///
  /// Returns it.
  ///
  /// Throws an [ArgumentError] when windows-1252 has no byte for [code].
  static int _encode(int code, int index) {
    if (code < 0x80 || (code >= 0xA0 && code <= 0xFF)) {
      return code;
    }
    final int high = windows1252High.indexOf(code);
    if (high == -1) {
      throw ArgumentError.value(
        index,
        'index',
        'holds U+${code.toRadixString(16).toUpperCase().padLeft(4, '0')}, '
            'which windows-1252 cannot represent',
      );
    }
    return 0x80 + high;
  }
}
