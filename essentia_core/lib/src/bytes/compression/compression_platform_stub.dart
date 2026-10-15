/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:typed_data';

import 'package:essentia_core/src/bytes/compression/compression_format.dart';
import 'package:meta/meta.dart';

/// Compresses [input] into [format] on a platform that offers no
/// compression.
///
/// Returns a stream that fails with an [UnsupportedError].
@internal
Stream<Uint8List> platformCompress(
  Stream<List<int>> input,
  CompressionFormat format,
  int level,
) => Stream<Uint8List>.error(
  UnsupportedError(
    '${format.webName} needs dart:io or a browser with CompressionStream',
  ),
);

/// Decompresses the [format] of [input] on a platform that offers no
/// compression.
///
/// Returns a stream that fails with an [UnsupportedError].
@internal
Stream<Uint8List> platformDecompress(
  Stream<List<int>> input,
  CompressionFormat format,
) => Stream<Uint8List>.error(
  UnsupportedError(
    '${format.webName} needs dart:io or a browser with DecompressionStream',
  ),
);
