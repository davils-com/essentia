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

import 'dart:io' show ZLibDecoder, ZLibEncoder;
import 'dart:typed_data';

import 'package:essentia_compression/src/compression_format.dart';
import 'package:meta/meta.dart';

/// Compresses [input] into [format] at compression [level], 0 to 9, with
/// the zlib of `dart:io`.
///
/// Returns the compressed chunks.
@internal
Stream<Uint8List> platformCompress(
  Stream<List<int>> input,
  CompressionFormat format,
  int level,
) => ZLibEncoder(
  gzip: format == CompressionFormat.gzip,
  raw: format == CompressionFormat.raw,
  level: level,
).bind(input).map(_bytes);

/// Decompresses the [format] of [input] with the zlib of `dart:io`.
///
/// Returns the decompressed chunks, which fail with a [FormatException]
/// where the data is not valid.
@internal
Stream<Uint8List> platformDecompress(
  Stream<List<int>> input,
  CompressionFormat format,
) => ZLibDecoder(raw: format == CompressionFormat.raw).bind(input).map(_bytes);

/// [chunk] as a [Uint8List], copied only when it is not one.
///
/// Returns the bytes.
Uint8List _bytes(List<int> chunk) {
  if (chunk is Uint8List) {
    return chunk;
  }
  return Uint8List.fromList(chunk);
}
