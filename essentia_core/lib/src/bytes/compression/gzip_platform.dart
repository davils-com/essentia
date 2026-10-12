/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// Where gzip is compressed and decompressed: with the zlib of `dart:io`
/// where it is, with the `CompressionStream` of the browser on the web,
/// and nowhere else.
library;

export 'package:essentia_core/src/bytes/compression/gzip_platform_stub.dart'
    if (dart.library.io) 'package:essentia_core/src/bytes/compression/gzip_platform_io.dart'
    if (dart.library.js_interop) 'package:essentia_core/src/bytes/compression/gzip_platform_web.dart';
