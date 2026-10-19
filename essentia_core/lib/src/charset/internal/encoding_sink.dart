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
