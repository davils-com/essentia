/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:typed_data';

import 'package:meta/meta.dart';

/// Compresses [input] into gzip on a platform that offers no compression.
///
/// Returns a stream that fails with an [UnsupportedError].
@internal
Stream<Uint8List> platformGzip(Stream<List<int>> input, int level) =>
    Stream<Uint8List>.error(
      UnsupportedError(
        'gzip needs dart:io or a browser with CompressionStream',
      ),
    );

/// Decompresses the gzip of [input] on a platform that offers no
/// compression.
///
/// Returns a stream that fails with an [UnsupportedError].
@internal
Stream<Uint8List> platformGunzip(Stream<List<int>> input) =>
    Stream<Uint8List>.error(
      UnsupportedError(
        'gzip needs dart:io or a browser with DecompressionStream',
      ),
    );
