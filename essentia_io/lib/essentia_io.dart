/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// Byte input and output for Dart, ported from ktor-io: the segmented
/// `Buffer`, the byte channels a writer and a reader share with back
/// pressure, the operations that read and write numbers, bytes and lines
/// and scan for a delimiter, the `writer` and `reader` coroutines of
/// `essentia_coroutines`, and the bridges to Dart's streams.
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
