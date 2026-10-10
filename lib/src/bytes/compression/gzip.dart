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

import 'package:essentia/src/bytes/compression/gzip_frame_check.dart';
import 'package:essentia/src/bytes/compression/gzip_platform.dart';
import 'package:essentia/src/bytes/crc32.dart';

/// A transformer that compresses a stream of bytes into one gzip member of
/// RFC 1952, at compression [level] from 0, stored, to 9, smallest; 6, the
/// default of zlib, balances size and speed.
///
/// It runs on the zlib of `dart:io` where that is, and on the
/// `CompressionStream('gzip')` of the browser on the web, which picks its
/// own level and ignores [level]. The compressed bytes differ between the
/// two, and every gzip reader reads both.
///
/// ```dart
/// await File('app.log.gz').openWrite().addStream(
///   File('app.log').openRead().transform(gzipEncoder()),
/// );
/// ```
///
/// Returns the transformer.
///
/// Throws a [RangeError] if [level] is not between 0 and 9. The stream it
/// returns fails with an [UnsupportedError] on a platform with neither
/// `dart:io` nor a browser.
StreamTransformer<List<int>, Uint8List> gzipEncoder({int level = 6}) {
  RangeError.checkValueInInterval(level, 0, 9, 'level');
  return StreamTransformer<List<int>, Uint8List>.fromBind(
    (input) => platformGzip(input, level),
  );
}

/// A transformer that decompresses one gzip member of RFC 1952 and checks
/// it: its header, the CRC-32 and the length its trailer records.
///
/// A failure of the stream it transforms comes out as it is. The
/// decompressed chunks are handed on as they come, so a member that turns
/// out to be corrupt fails only at its end; a reader that must not act on
/// corrupt data waits for the stream to be done, or uses [gunzip].
///
/// Data behind the member, another member included, is refused. The one
/// exception is a member followed by a verbatim copy of its own last eight
/// bytes, such as the same member again: the zlib of `dart:io` stops at the
/// end of the first member, and the trailer still matches, so on the VM
/// that reads as the first member alone.
///
/// Returns the transformer, whose stream fails with a [FormatException]
/// for data that is not gzip, is damaged, cut short or followed by more
/// data, and with an [UnsupportedError] on a platform with neither
/// `dart:io` nor a browser.
StreamTransformer<List<int>, Uint8List> gzipDecoder() =>
    StreamTransformer<List<int>, Uint8List>.fromBind(_decompressed);

/// Compresses [bytes] into one gzip member at compression [level], as
/// [gzipEncoder] does.
///
/// ```dart
/// final Uint8List body = await gzip(utf8.encode(json));
/// ```
///
/// Returns the compressed bytes.
///
/// Throws a [RangeError] if [level] is not between 0 and 9; the future
/// fails with an [UnsupportedError] on a platform with neither `dart:io`
/// nor a browser.
Future<Uint8List> gzip(List<int> bytes, {int level = 6}) => _collect(
  Stream<List<int>>.value(bytes).transform(gzipEncoder(level: level)),
);

/// Decompresses [bytes], one gzip member, and checks it, as [gzipDecoder]
/// does.
///
/// Returns the decompressed bytes, or a future that fails with a
/// [FormatException] for data that is not gzip, is damaged, cut short or
/// followed by more data.
Future<Uint8List> gunzip(List<int> bytes) =>
    _collect(Stream<List<int>>.value(bytes).transform(gzipDecoder()));

/// Decompresses [input] on the platform and checks its frame.
///
/// Returns the decompressed chunks.
Stream<Uint8List> _decompressed(Stream<List<int>> input) async* {
  final frame = GzipFrameCheck();
  final crc = Crc32();
  var length = 0;
  await for (final Uint8List chunk in platformGunzip(input.map(frame.see))) {
    crc.add(chunk);
    length += chunk.length;
    yield chunk;
  }
  frame.verify(crc.value, length);
}

/// Joins [chunks] into one list.
///
/// Returns the bytes.
Future<Uint8List> _collect(Stream<Uint8List> chunks) async {
  final builder = BytesBuilder(copy: false);
  await chunks.forEach(builder.add);
  return builder.takeBytes();
}
