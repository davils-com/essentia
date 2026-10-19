/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:typed_data';

/// The reflected polynomial of CRC-32, as gzip, zip and PNG use it.
const _polynomial = 0xEDB88320;

/// All 32 bits set.
const _mask = 0xFFFFFFFF;

/// The running CRC-32 of the bytes it was handed, the check gzip, zip and
/// PNG store beside their data.
///
/// Written with 32-bit operations only, so it gives the same answer on the
/// web, where a bit operation is 32-bit.
///
/// ```dart
/// Crc32.of(utf8.encode('123456789')); // 0xCBF43926
///
/// final crc = Crc32()
///   ..add(utf8.encode('12345'))
///   ..add(utf8.encode('6789'));
/// crc.value; // 0xCBF43926
/// ```
final class Crc32 {
  /// Creates the check of nothing yet, whose [value] is 0.
  Crc32();

  /// The step of every byte value, made once.
  static final Uint32List _table = _tableOf();

  /// The register, inverted.
  int _register = _mask;

  /// The check of everything handed over so far, 0 to 2^32 - 1.
  int get value => (_register ^ _mask) & _mask;

  /// Takes [bytes] into the check; of every element only its low eight bits
  /// count.
  void add(List<int> bytes) {
    int register = _register;
    for (final byte in bytes) {
      register = _table[(register ^ byte) & 0xFF] ^ (register >>> 8);
    }
    _register = register & _mask;
  }

  /// The check of [bytes] alone.
  ///
  /// Returns it, 0 to 2^32 - 1.
  static int of(List<int> bytes) => (Crc32()..add(bytes)).value;

  /// The step of every byte value.
  ///
  /// Returns the table.
  static Uint32List _tableOf() {
    final table = Uint32List(256);
    for (var index = 0; index < 256; index++) {
      var entry = index;
      for (var bit = 0; bit < 8; bit++) {
        entry = entry & 1 == 1 ? _polynomial ^ (entry >>> 1) : entry >>> 1;
      }
      table[index] = entry;
    }
    return table;
  }
}
