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

import 'package:essentia_compression/src/checksum/adler32.dart';
import 'package:essentia_compression/src/compression_format.dart';
import 'package:essentia_compression/src/compression_platform.dart';
import 'package:essentia_compression/src/zlib_frame_check.dart';

/// A transformer that compresses a stream of bytes into deflate data, RFC
/// 1951, at compression [level] from 0, stored, to 9, smallest.
///
/// By default the data is wrapped as a zlib stream, RFC 1950, with its
/// header and its Adler-32: what HTTP calls the `deflate` content coding.
/// With [raw] it is deflate data alone, as a zip entry or a WebSocket
/// message compressed by permessage-deflate carries it.
///
/// It runs on the zlib of `dart:io` where that is, and on the
/// `CompressionStream` of the browser on the web, which picks its own
/// level and ignores [level].
///
/// Returns the transformer.
///
/// Throws a [RangeError] if [level] is not between 0 and 9. The stream it
/// returns fails with an [UnsupportedError] on a platform with neither
/// `dart:io` nor a browser.
StreamTransformer<List<int>, Uint8List> deflateEncoder({
  int level = 6,
  bool raw = false,
}) {
  RangeError.checkValueInInterval(level, 0, 9, 'level');
  final CompressionFormat format = raw
      ? CompressionFormat.raw
      : CompressionFormat.zlib;
  return StreamTransformer<List<int>, Uint8List>.fromBind(
    (input) => platformCompress(input, format, level),
  );
}

/// A transformer that decompresses deflate data, RFC 1951.
///
/// By default it reads a zlib stream, RFC 1950, and checks it: its header
/// and the Adler-32 of its trailer, so that data cut short, damaged or
/// followed by more data fails. With [raw] it reads deflate data alone,
/// which has no trailer to check: on the web the browser still refuses
/// data cut short, while the zlib of `dart:io` hands on what the data held
/// up to where it ends.
///
/// The decompressed chunks are handed on as they come, so a corrupt stream
/// fails only at its end; a reader that must not act on corrupt data
/// waits for the stream to be done, or uses [inflate].
///
/// Returns the transformer, whose stream fails with a [FormatException]
/// for data that is not deflate or not zlib, and with an
/// [UnsupportedError] on a platform with neither `dart:io` nor a browser.
StreamTransformer<List<int>, Uint8List> deflateDecoder({bool raw = false}) =>
    StreamTransformer<List<int>, Uint8List>.fromBind(
      (input) => raw
          ? platformDecompress(input, CompressionFormat.raw)
          : _checkedZlib(input),
    );

/// Compresses [bytes] into deflate data at compression [level], as
/// [deflateEncoder] does: a zlib stream, or deflate data alone with [raw].
///
/// Returns the compressed bytes.
///
/// Throws a [RangeError] if [level] is not between 0 and 9; the future
/// fails with an [UnsupportedError] on a platform with neither `dart:io`
/// nor a browser.
Future<Uint8List> deflate(List<int> bytes, {int level = 6, bool raw = false}) =>
    _collect(
      Stream<List<int>>.value(bytes)
          .transform(deflateEncoder(level: level, raw: raw)),
    );

/// Decompresses [bytes], a zlib stream or with [raw] deflate data alone,
/// as [deflateDecoder] does.
///
/// Returns the decompressed bytes, or a future that fails with a
/// [FormatException] for data that is not valid.
Future<Uint8List> inflate(List<int> bytes, {bool raw = false}) => _collect(
  Stream<List<int>>.value(bytes).transform(deflateDecoder(raw: raw)),
);

/// Decompresses the zlib stream [input] on the platform and checks its
/// frame.
///
/// Returns the decompressed chunks.
Stream<Uint8List> _checkedZlib(Stream<List<int>> input) async* {
  final frame = ZlibFrameCheck();
  final adler = Adler32();
  await for (final Uint8List chunk in platformDecompress(
    input.map(frame.see),
    CompressionFormat.zlib,
  )) {
    adler.add(chunk);
    yield chunk;
  }
  frame.verify(adler.value);
}

/// Joins [chunks] into one list.
///
/// Returns the bytes.
Future<Uint8List> _collect(Stream<Uint8List> chunks) async {
  final builder = BytesBuilder(copy: false);
  await chunks.forEach(builder.add);
  return builder.takeBytes();
}
