/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:convert';

import 'package:essentia_core/src/charset/charset.dart';
import 'package:meta/meta.dart';

/// A charset made of an [encoder] and a [decoder].
@internal
final class BuiltCharset extends Charset {
  /// Creates the charset [name], also known as [aliases], that encodes with
  /// [encoder] and decodes with [decoder].
  const BuiltCharset(super.name, super.aliases, this.encoder, this.decoder);

  /// Turns text into bytes.
  @override
  final Converter<String, List<int>> encoder;

  /// Turns bytes into text.
  @override
  final Converter<List<int>, String> decoder;
}
