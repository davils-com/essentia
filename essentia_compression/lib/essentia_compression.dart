/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// Compression for Essentia.
///
/// gzip, RFC 1952, zlib streams and raw deflate data, RFC 1950 and 1951,
/// compressed and decompressed with their frames checked, a decoder of
/// Brotli, RFC 7932, and the running checks CRC-32 and Adler-32. gzip and
/// deflate run on the zlib of `dart:io` and on the `CompressionStream` of
/// the browser; the Brotli decoder and the checks run alike on every Dart
/// platform, the web and WebAssembly included.
library;

export 'src/brotli.dart';
export 'src/checksum/adler32.dart';
export 'src/checksum/crc32.dart';
export 'src/deflate.dart';
export 'src/gzip.dart';
