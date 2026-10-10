/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:io' show ZLibDecoder, ZLibEncoder;
import 'dart:typed_data';

import 'package:meta/meta.dart';

/// Compresses [input] into one gzip member at compression [level], 0 to 9,
/// with the zlib of `dart:io`.
///
/// Returns the compressed chunks.
@internal
Stream<Uint8List> platformGzip(Stream<List<int>> input, int level) =>
    ZLibEncoder(gzip: true, level: level).bind(input).map(_bytes);

/// Decompresses the gzip of [input] with the zlib of `dart:io`.
///
/// Returns the decompressed chunks, which fail with a [FormatException]
/// where the data is not valid.
@internal
Stream<Uint8List> platformGunzip(Stream<List<int>> input) =>
    ZLibDecoder().bind(input).map(_bytes);

/// [chunk] as a [Uint8List], copied only when it is not one.
///
/// Returns the bytes.
Uint8List _bytes(List<int> chunk) {
  if (chunk is Uint8List) {
    return chunk;
  }
  return Uint8List.fromList(chunk);
}
