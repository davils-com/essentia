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

import 'package:meta/meta.dart';

/// One step of the binary units.
const _binaryStep = 1024;

/// One step of the decimal units.
const _decimalStep = 1000;

/// The units a size may be written in, each with the bytes it holds. A unit
/// comes before every unit its suffix ends with, so that `KiB` is found
/// before `B`.
const _units = <(String, int)>[
  ('PiB', _binaryStep * _binaryStep * _binaryStep * _binaryStep * _binaryStep),
  ('TiB', _binaryStep * _binaryStep * _binaryStep * _binaryStep),
  ('GiB', _binaryStep * _binaryStep * _binaryStep),
  ('MiB', _binaryStep * _binaryStep),
  ('KiB', _binaryStep),
  (
    'PB',
    _decimalStep * _decimalStep * _decimalStep * _decimalStep * _decimalStep,
  ),
  ('TB', _decimalStep * _decimalStep * _decimalStep * _decimalStep),
  ('GB', _decimalStep * _decimalStep * _decimalStep),
  ('MB', _decimalStep * _decimalStep),
  ('kB', _decimalStep),
  ('B', 1),
];

/// A whole number of digits.
final _whole = RegExp(r'^[0-9]+$');

/// A number of digits with a decimal fraction.
final _fractional = RegExp(r'^[0-9]*\.[0-9]+$');

/// An amount of bytes, written the way people write it: `512KiB`, `10MB`,
/// `1.5GiB` or `4096`.
///
/// ```dart
/// final ByteSize limit = ByteSize.parse('16MiB');
/// limit.bytes; // 16777216
/// limit.toString(); // 16MiB
/// ```
///
/// The binary units `KiB` to `PiB` step by 1024 and the decimal units `kB`
/// to `PB` by 1000: `1KiB` is not `1kB`. A unit is matched regardless of
/// case. A size is never negative and at most [maxBytes], 2^53 - 1, the
/// largest integer every Dart platform holds exactly.
@immutable
final class ByteSize implements Comparable<ByteSize> {
  /// The size of [bytes] bytes, which must be between zero and [maxBytes].
  const ByteSize(this.bytes)
    : assert(bytes >= 0, 'a size is never negative'),
      assert(bytes <= maxBytes, 'a size is at most maxBytes');

  /// The largest size, 2^53 - 1 bytes, the largest integer that is exact
  /// on the web as well.
  static const maxBytes = 9007199254740991;

  /// No bytes at all.
  static const zero = ByteSize(0);

  /// The number of bytes.
  final int bytes;

  /// Reads [text], such as `512KiB`, `10 MB`, `1.5GiB` or `4096`, as a size.
  ///
  /// Returns the size.
  ///
  /// Throws a [FormatException] if the text is not a size, is negative, is
  /// not a whole number of bytes or is larger than [maxBytes]. The message
  /// does not quote the text.
  static ByteSize parse(String text) =>
      tryParse(text) ?? (throw const FormatException('not a byte size'));

  /// Reads [text] as a size, or answers `null` when [parse] would refuse it.
  ///
  /// Returns the size, or `null`.
  static ByteSize? tryParse(String text) {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final String lower = trimmed.toLowerCase();
    for (final (String suffix, int step) in _units) {
      if (lower.endsWith(suffix.toLowerCase())) {
        final String amount = trimmed
            .substring(0, trimmed.length - suffix.length)
            .trim();
        return _scaled(amount, step);
      }
    }
    return _scaled(trimmed, 1);
  }

  /// Whether this size is smaller than [other].
  ///
  /// Returns `true` when it holds fewer bytes.
  bool operator <(ByteSize other) => bytes < other.bytes;

  /// Whether this size is at most [other].
  ///
  /// Returns `true` when it holds no more bytes.
  bool operator <=(ByteSize other) => bytes <= other.bytes;

  /// Whether this size is larger than [other].
  ///
  /// Returns `true` when it holds more bytes.
  bool operator >(ByteSize other) => bytes > other.bytes;

  /// Whether this size is at least [other].
  ///
  /// Returns `true` when it holds no fewer bytes.
  bool operator >=(ByteSize other) => bytes >= other.bytes;

  /// Orders sizes by their bytes.
  ///
  /// Returns a negative number, zero or a positive number.
  @override
  int compareTo(ByteSize other) => bytes.compareTo(other.bytes);

  /// Two sizes are equal when they hold the same bytes.
  @override
  bool operator ==(Object other) => other is ByteSize && other.bytes == bytes;

  /// The hash of the bytes.
  @override
  int get hashCode => bytes.hashCode;

  /// The size in the largest binary unit that holds it exactly, such as
  /// `16MiB`, or in bytes, such as `1500B`, when no binary unit does.
  ///
  /// [parse] reads it back to the same size.
  @override
  String toString() {
    for (final (String suffix, int step) in _units) {
      final bool binary = suffix.endsWith('iB');
      if (binary && step <= bytes && bytes % step == 0) {
        return '${bytes ~/ step}$suffix';
      }
    }
    return '${bytes}B';
  }
}

/// Multiplies [amount] by [step].
///
/// Returns the size, or `null` when [amount] is not a number or the product
/// is not a whole number of bytes between zero and [ByteSize.maxBytes].
ByteSize? _scaled(String amount, int step) {
  if (_whole.hasMatch(amount)) {
    final BigInt product = BigInt.parse(amount) * BigInt.from(step);
    if (product > BigInt.from(ByteSize.maxBytes)) {
      return null;
    }
    return ByteSize(product.toInt());
  }
  if (!_fractional.hasMatch(amount)) {
    return null;
  }
  final double product = double.parse(amount) * step;
  if (product % 1 != 0 || product > ByteSize.maxBytes) {
    return null;
  }
  return ByteSize(product.toInt());
}
