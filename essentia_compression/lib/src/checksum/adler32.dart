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

/// The modulus of Adler-32, the largest prime below 2^16.
const _modulus = 65521;

/// How many bytes may be summed before the sums must be reduced, so that
/// they stay exact on the web, where an integer is exact up to 2^53.
const _block = 5552;

/// The running Adler-32 of the bytes it was handed, RFC 1950, the check a
/// zlib stream stores behind its data.
///
/// ```dart
/// Adler32.of(ascii.encode('Wikipedia')); // 0x11E60398
/// ```
final class Adler32 {
  /// Creates the check of nothing yet, whose [value] is 1.
  Adler32();

  /// The sum of the bytes plus one, modulo [_modulus].
  var _low = 1;

  /// The sum of the running [_low] values, modulo [_modulus].
  var _high = 0;

  /// The check of everything handed over so far, 0 to 2^32 - 1.
  int get value => _high * 0x10000 + _low;

  /// Takes [bytes] into the check; of every element only its low eight bits
  /// count.
  void add(List<int> bytes) {
    int low = _low;
    int high = _high;
    var index = 0;
    while (index < bytes.length) {
      final int end = index + _block < bytes.length
          ? index + _block
          : bytes.length;
      for (; index < end; index++) {
        low += bytes[index] & 0xFF;
        high += low;
      }
      low %= _modulus;
      high %= _modulus;
    }
    _low = low;
    _high = high;
  }

  /// The check of [bytes] alone.
  ///
  /// Returns it, 0 to 2^32 - 1.
  static int of(List<int> bytes) => (Adler32()..add(bytes)).value;
}
