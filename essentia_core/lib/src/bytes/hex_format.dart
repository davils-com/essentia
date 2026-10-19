/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
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
