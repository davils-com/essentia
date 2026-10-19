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

/// Byte input and output for Dart: the segmented `Buffer`, the byte
/// channels a writer and a reader share with back pressure, the operations
/// that read and write numbers, bytes and lines and scan for a delimiter,
/// the `writer` and `reader` coroutines of `essentia_coroutines`, and the
/// bridges to Dart's streams.
///
/// It runs on every Dart platform, the web and WebAssembly included.
library;

export 'src/buffer/buffer.dart';
export 'src/channel/byte_channel.dart';
export 'src/channel/byte_read_channel.dart';
export 'src/channel/byte_write_channel.dart';
export 'src/channel/counted_byte_read_channel.dart';
export 'src/channel/counted_byte_write_channel.dart';
export 'src/channel/line_ending.dart';
export 'src/exception/closed_byte_channel_exception.dart';
export 'src/exception/closed_read_channel_exception.dart';
export 'src/exception/closed_write_channel_exception.dart';
export 'src/exception/concurrent_io_exception.dart';
export 'src/exception/connection_closed_exception.dart';
export 'src/exception/eof_exception.dart';
export 'src/exception/io_exception.dart';
export 'src/exception/too_long_line_exception.dart';
export 'src/job/channel_job.dart';
export 'src/job/channel_job_operations.dart';
export 'src/job/coroutine_scope_byte_channels.dart';
export 'src/job/reader_job.dart';
export 'src/job/reader_scope.dart';
export 'src/job/writer_job.dart';
export 'src/job/writer_scope.dart';
export 'src/operations/byte_read_channel_operations.dart';
export 'src/operations/byte_write_channel_operations.dart';
export 'src/stream/byte_read_channel_streams.dart';
