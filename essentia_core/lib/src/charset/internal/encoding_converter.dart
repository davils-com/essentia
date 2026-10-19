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
