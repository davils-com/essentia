/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:convert';

import 'package:essentia_core/src/charset/internal/byte_decoding.dart';
import 'package:essentia_core/src/charset/internal/decoding_sink.dart';
import 'package:meta/meta.dart';

/// A decoder that runs a fresh [ByteDecoding] for every conversion.
@internal
final class DecodingConverter extends Converter<List<int>, String> {
  /// Creates the decoder that starts each conversion with [_start].
  const DecodingConverter(this._start);

  /// Creates the state of one conversion.
  final ByteDecoding Function() _start;

  /// Decodes [input] at once.
  ///
  /// Returns the text.
  @override
  String convert(List<int> input) {
    final ByteDecoding decoding = _start();
    return decoding.add(input, 0, input.length) + decoding.close();
  }

  /// Starts decoding chunks into [sink].
  ///
  /// Returns the sink the chunks go to.
  @override
  ByteConversionSink startChunkedConversion(Sink<String> sink) =>
      DecodingSink(_start(), sink);
}
