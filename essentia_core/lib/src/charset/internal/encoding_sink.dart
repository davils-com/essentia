/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:convert';

import 'package:essentia_core/src/charset/internal/string_encoding.dart';
import 'package:meta/meta.dart';

/// The sink of a chunked encoding.
@internal
final class EncodingSink with StringConversionSink {
  /// Creates the sink that encodes with [_encoding] into [_out].
  EncodingSink(this._encoding, this._out);

  /// The state of the encoding.
  final StringEncoding _encoding;

  /// Where the bytes go.
  final Sink<List<int>> _out;

  /// Encodes [chunk] from [start] to [end], and ends with it if [isLast].
  @override
  void addSlice(String chunk, int start, int end, bool isLast) {
    RangeError.checkValidRange(start, end, chunk.length);
    final List<int> bytes = _encoding.add(chunk, start, end);
    if (bytes.isNotEmpty) {
      _out.add(bytes);
    }
    if (isLast) {
      close();
    }
  }

  /// Ends the encoding.
  @override
  void close() {
    final List<int> bytes = _encoding.close();
    if (bytes.isNotEmpty) {
      _out.add(bytes);
    }
    _out.close();
  }
}
