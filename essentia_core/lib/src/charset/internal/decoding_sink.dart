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
import 'package:meta/meta.dart';

/// The sink of a chunked decoding.
@internal
final class DecodingSink with ByteConversionSink {
  /// Creates the sink that decodes with [_decoding] into [_out].
  DecodingSink(this._decoding, this._out);

  /// The state of the decoding.
  final ByteDecoding _decoding;

  /// Where the text goes.
  final Sink<String> _out;

  /// Decodes [chunk].
  @override
  void add(List<int> chunk) {
    addSlice(chunk, 0, chunk.length, false);
  }

  /// Decodes [chunk] from [start] to [end], and ends with it if [isLast].
  @override
  void addSlice(List<int> chunk, int start, int end, bool isLast) {
    RangeError.checkValidRange(start, end, chunk.length);
    final String text = _decoding.add(chunk, start, end);
    if (text.isNotEmpty) {
      _out.add(text);
    }
    if (isLast) {
      close();
    }
  }

  /// Ends the decoding.
  @override
  void close() {
    final String text = _decoding.close();
    if (text.isNotEmpty) {
      _out.add(text);
    }
    _out.close();
  }
}
