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
