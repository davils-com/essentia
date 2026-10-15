/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:convert';
import 'dart:typed_data';

import 'package:essentia_core/src/charset/internal/encoding_sink.dart';
import 'package:essentia_core/src/charset/internal/string_encoding.dart';
import 'package:meta/meta.dart';

/// An encoder that runs a fresh [StringEncoding] for every conversion.
@internal
final class EncodingConverter extends Converter<String, List<int>> {
  /// Creates the encoder that starts each conversion with [_start].
  const EncodingConverter(this._start);

  /// Creates the state of one conversion.
  final StringEncoding Function() _start;

  /// Encodes [input] at once.
  ///
  /// Returns the bytes.
  ///
  /// Throws an [ArgumentError] for a character the charset cannot
  /// represent.
  @override
  Uint8List convert(String input) {
    final StringEncoding encoding = _start();
    return Uint8List.fromList(<int>[
      ...encoding.add(input, 0, input.length),
      ...encoding.close(),
    ]);
  }

  /// Starts encoding chunks into [sink].
  ///
  /// Returns the sink the chunks go to.
  @override
  StringConversionSink startChunkedConversion(Sink<List<int>> sink) =>
      EncodingSink(_start(), sink);
}
