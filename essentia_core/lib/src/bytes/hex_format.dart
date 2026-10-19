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

/// How bytes are written as hexadecimal digits and read back.
///
/// Every byte is two digits, wrapped in [bytePrefix] and [byteSuffix], and
/// neighbouring bytes are joined by [byteSeparator]. Reading accepts either
/// case, whatever [upperCase] says, and nothing but the configured pieces in
/// between.
///
/// ```dart
/// final HexFormat colons = hexFormat((it) => it.byteSeparator = ':');
///
/// [0xde, 0xad].toHexString(colons);
/// ```
@immutable
final class HexFormat {
  /// Creates a format.
  const HexFormat({
    this.upperCase = false,
    this.byteSeparator = '',
    this.bytePrefix = '',
    this.byteSuffix = '',
  });

  /// Lowercase digits without separators.
  static const defaultFormat = HexFormat();

  /// Uppercase digits without separators.
  static const upperCaseFormat = HexFormat(upperCase: true);

  /// Whether the digits `a` to `f` are written in upper case.
  final bool upperCase;

  /// What is written between two bytes.
  final String byteSeparator;

  /// What is written before the two digits of every byte.
  final String bytePrefix;

  /// What is written after the two digits of every byte.
  final String byteSuffix;

  /// Whether this format writes nothing but the digits.
  bool get isDigitsOnly =>
      byteSeparator.isEmpty && bytePrefix.isEmpty && byteSuffix.isEmpty;

  /// Two formats are equal when every piece is.
  @override
  bool operator ==(Object other) =>
      other is HexFormat &&
      other.upperCase == upperCase &&
      other.byteSeparator == byteSeparator &&
      other.bytePrefix == bytePrefix &&
      other.byteSuffix == byteSuffix;

  /// A hash code of every piece.
  @override
  int get hashCode =>
      Object.hash(upperCase, byteSeparator, bytePrefix, byteSuffix);

  /// Names every piece.
  @override
  String toString() =>
      'HexFormat(upperCase: $upperCase, byteSeparator: "$byteSeparator", '
      'bytePrefix: "$bytePrefix", byteSuffix: "$byteSuffix")';
}
