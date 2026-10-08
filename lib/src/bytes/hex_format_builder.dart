/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/bytes/hex_format.dart';
import 'package:essentia/src/dsl/builder.dart';

/// The builder behind `hexFormat`, Kotlin's `HexFormat.Builder`.
final class HexFormatBuilder implements Builder<HexFormat> {
  /// Whether the digits `a` to `f` are written in upper case.
  var upperCase = false;

  /// What is written between two bytes.
  var byteSeparator = '';

  /// What is written before the two digits of every byte.
  var bytePrefix = '';

  /// What is written after the two digits of every byte.
  var byteSuffix = '';

  /// Produces the format.
  ///
  /// Returns the format.
  @override
  HexFormat build() => HexFormat(
    upperCase: upperCase,
    byteSeparator: byteSeparator,
    bytePrefix: bytePrefix,
    byteSuffix: byteSuffix,
  );
}
