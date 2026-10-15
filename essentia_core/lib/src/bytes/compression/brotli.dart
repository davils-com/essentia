/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';
import 'dart:typed_data';

import 'package:essentia_core/src/bytes/compression/brotli/brotli_stream_decoder.dart';

/// A transformer that decompresses one Brotli stream of RFC 7932, as HTTP
/// knows it by the content coding `br`.
///
/// The decoder is written in Dart and runs alike on the VM, on the web
/// and in WebAssembly, with neither `dart:io` nor a browser codec. It
/// decodes the stream as its bytes arrive and hands the bytes on in
/// chunks of up to 16 KiB, holding a window of at most 16 MiB, the
/// largest one RFC 7932 allows, as the stream asks for.
///
/// A failure of the stream it transforms comes out as it is. The bytes
/// are handed on as they are decoded, so a stream that turns out to be
/// damaged fails only where the damage is; a reader that must not act on
/// damaged data waits for the stream to be done, or uses [unbrotli].
///
/// ```dart
/// final Stream<Uint8List> body = response.transform(brotliDecoder());
/// ```
///
/// Returns the transformer, whose stream fails with a [FormatException]
/// for data that is not Brotli, is damaged, cut short or followed by more
/// data.
StreamTransformer<List<int>, Uint8List> brotliDecoder() =>
    StreamTransformer<List<int>, Uint8List>.fromBind(_decompressed);

/// Decompresses [bytes], one Brotli stream, as [brotliDecoder] does.
///
/// Returns the decompressed bytes, or a future that fails with a
/// [FormatException] for data that is not Brotli, is damaged, cut short
/// or followed by more data.
Future<Uint8List> unbrotli(List<int> bytes) async {
  final builder = BytesBuilder(copy: false);
  await Stream<List<int>>.value(bytes)
      .transform(brotliDecoder())
      .forEach(builder.add);
  return builder.takeBytes();
}

/// Decompresses [input].
///
/// Returns the decompressed chunks.
Stream<Uint8List> _decompressed(Stream<List<int>> input) async* {
  final decoder = BrotliStreamDecoder();
  await for (final List<int> chunk in input) {
    yield* Stream<Uint8List>.fromIterable(decoder.add(chunk));
  }
  yield* Stream<Uint8List>.fromIterable(decoder.close());
}
