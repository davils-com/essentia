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
import 'dart:typed_data';

import 'package:essentia_core/src/bytes/byte_list_content.dart';
import 'package:essentia_core/src/bytes/byte_list_hex.dart';
import 'package:essentia_core/src/bytes/hex_format.dart';
import 'package:meta/meta.dart';

/// An immutable sequence of bytes.
///
/// It copies what it is made from and hands out copies or unmodifiable
/// views, so nobody holding one can change it under somebody else. Two byte
/// strings are equal when their bytes are, and they sort by their bytes read
/// unsigned.
///
/// ```dart
/// final ByteString magic = 'cafe'.hexToByteString();
///
/// magic.size;
/// magic.toHexString();
/// ```
@immutable
final class ByteString implements Comparable<ByteString> {
  /// Creates a byte string holding a copy of the low eight bits of every
  /// element of [bytes].
  ByteString(List<int> bytes) : _bytes = Uint8List.fromList(bytes);

  /// Creates a byte string around [bytes], which nobody else holds.
  const ByteString._(this._bytes);

  /// The byte string without bytes.
  static final empty = ByteString._(Uint8List(0));

  /// The bytes, owned by this byte string alone.
  final Uint8List _bytes;

  /// How many bytes there are.
  int get size => _bytes.length;

  /// Whether there are no bytes.
  bool get isEmpty => _bytes.isEmpty;

  /// Whether there is at least one byte.
  bool get isNotEmpty => _bytes.isNotEmpty;

  /// An unmodifiable view of the bytes.
  ///
  /// Reading the view costs no copy.
  Uint8List get bytes => _bytes.asUnmodifiableView();

  /// The byte at [index], between 0 and 255.
  ///
  /// Throws a [RangeError] when [index] is outside the byte string.
  int operator [](int index) => _bytes[index];

  /// Copies the bytes from [start] up to [end] into a new list.
  ///
  /// Returns the copy, which the caller owns.
  ///
  /// Throws a [RangeError] when the range is outside the byte string.
  @useResult
  Uint8List toByteArray([int start = 0, int? end]) =>
      Uint8List.fromList(_bytes.sublist(start, end));

  /// The bytes from [start] up to [end].
  ///
  /// Returns a byte string of those bytes.
  ///
  /// Throws a [RangeError] when the range is outside the byte string.
  @useResult
  ByteString substring(int start, [int? end]) =>
      ByteString._(_bytes.sublist(start, end));

  /// Whether the bytes begin with those of [prefix].
  ///
  /// Returns `true` when they do.
  bool startsWith(ByteString prefix) =>
      prefix.size <= size &&
      _bytes.sublist(0, prefix.size).contentEquals(prefix._bytes);

  /// Whether the bytes end with those of [suffix].
  ///
  /// Returns `true` when they do.
  bool endsWith(ByteString suffix) =>
      suffix.size <= size &&
      _bytes.sublist(size - suffix.size).contentEquals(suffix._bytes);

  /// Where [byte] first occurs at or after [start].
  ///
  /// Returns its index, or -1 when it does not occur.
  int indexOf(int byte, [int start = 0]) => _bytes.indexOf(byte, start);

  /// Writes the bytes as hexadecimal digits in [format].
  ///
  /// Returns the text.
  @useResult
  String toHexString([HexFormat format = HexFormat.defaultFormat]) =>
      _bytes.toHexString(format);

  /// Decodes the bytes as UTF-8.
  ///
  /// A malformed sequence becomes U+FFFD.
  ///
  /// Returns the text.
  @useResult
  String decodeToString() => utf8.decode(_bytes, allowMalformed: true);

  /// Compares the bytes read unsigned, then the sizes.
  ///
  /// Returns a negative number, zero or a positive number as this byte
  /// string sorts before, with or after [other].
  @override
  int compareTo(ByteString other) {
    final int shorter = size < other.size ? size : other.size;
    for (var index = 0; index < shorter; index++) {
      final int difference = _bytes[index] - other._bytes[index];
      if (difference != 0) {
        return difference;
      }
    }
    return size - other.size;
  }

  /// Two byte strings are equal when their bytes are.
  @override
  bool operator ==(Object other) =>
      other is ByteString && other._bytes.contentEquals(_bytes);

  /// A hash code of the bytes.
  @override
  int get hashCode => _bytes.contentHashCode();

  /// Describes the byte string as `ByteString(size=3 hex=010203)`.
  @override
  String toString() => 'ByteString(size=$size hex=${toHexString()})';
}
