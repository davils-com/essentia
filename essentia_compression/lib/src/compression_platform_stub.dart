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

import 'dart:typed_data';

import 'package:essentia_compression/src/compression_format.dart';
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
