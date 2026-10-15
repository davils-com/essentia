/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:essentia_core/src/bytes/compression/compression_format.dart';
import 'package:meta/meta.dart';

/// Compresses [input] into [format] with the `CompressionStream` of the
/// browser, which picks its own compression level and ignores [level].
///
/// Returns the compressed chunks.
@internal
Stream<Uint8List> platformCompress(
  Stream<List<int>> input,
  CompressionFormat format,
  int level,
) =>
    _pipe('CompressionStream', format, input, 'The browser could not compress');

/// Decompresses the [format] of [input] with the `DecompressionStream` of
/// the browser.
///
/// Returns the decompressed chunks, which fail with a [FormatException]
/// where the data is not valid.
@internal
Stream<Uint8List> platformDecompress(
  Stream<List<int>> input,
  CompressionFormat format,
) => _pipe(
  'DecompressionStream',
  format,
  input,
  'The data is not valid ${format.webName}',
);

/// Pipes [input] through a new stream of [format] of the browser class
/// [constructor], writing and reading at the same time.
///
/// A thin bridge: a listener that pauses stops the reading and with it the
/// writing, and one that cancels cancels the reader. A failure of [input]
/// comes out as it is; a failure of the browser as a [FormatException]
/// starting with [failing].
///
/// Returns the chunks that come out.
Stream<Uint8List> _pipe(
  String constructor,
  CompressionFormat format,
  Stream<List<int>> input,
  String failing,
) async* {
  final JSObject transform = globalContext
      .getProperty<JSFunction>(constructor.toJS)
      .callAsConstructor<JSObject>(format.webName.toJS);
  final JSObject writer = transform
      .getProperty<JSObject>('writable'.toJS)
      .callMethod<JSObject>('getWriter'.toJS);
  final JSObject reader = transform
      .getProperty<JSObject>('readable'.toJS)
      .callMethod<JSObject>('getReader'.toJS);
  (Object, StackTrace)? failure;
  unawaited(
    _feed(writer, input, (error, stackTrace) => failure = (error, stackTrace)),
  );
  var done = false;
  try {
    while (!done) {
      final JSObject result;
      try {
        result = await reader
            .callMethod<JSPromise<JSObject>>('read'.toJS)
            .toDart;
      } on Object catch (error) {
        final cause = failure;
        if (cause != null) {
          Error.throwWithStackTrace(cause.$1, cause.$2);
        }
        throw FormatException('$failing: $error');
      }
      done = result.getProperty<JSBoolean>('done'.toJS).toDart;
      if (!done) {
        yield result.getProperty<JSUint8Array>('value'.toJS).toDart;
      }
    }
  } finally {
    if (!done) {
      reader.callMethod<JSPromise<JSAny?>>('cancel'.toJS).toDart.ignore();
    }
  }
}

/// Writes every chunk of [input] to [writer] and closes it, or hands a
/// failure of [input] to [fail] and aborts the writer.
///
/// Returns a future that completes once [input] is written or failed; it
/// never fails itself.
Future<void> _feed(
  JSObject writer,
  Stream<List<int>> input,
  void Function(Object error, StackTrace stackTrace) fail,
) async {
  try {
    await for (final List<int> chunk in input) {
      if (!await _write(writer, chunk)) {
        return;
      }
    }
  } on Object catch (error, stackTrace) {
    fail(error, stackTrace);
    writer.callMethod<JSPromise<JSAny?>>('abort'.toJS).toDart.ignore();
    return;
  }
  writer.callMethod<JSPromise<JSAny?>>('close'.toJS).toDart.ignore();
}

/// Writes [chunk] to [writer] and waits until the browser took it.
///
/// Returns `false` when the browser refused it, because the stream failed
/// or its reader was cancelled.
Future<bool> _write(JSObject writer, List<int> chunk) async {
  final Uint8List bytes = chunk is Uint8List
      ? chunk
      : Uint8List.fromList(chunk);
  try {
    await writer.callMethod<JSPromise<JSAny?>>('write'.toJS, bytes.toJS).toDart;
    return true;
  } on Object {
    return false;
  }
}
