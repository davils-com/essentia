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

import 'package:essentia_io/src/channel/byte_read_channel.dart';
import 'package:essentia_io/src/exception/io_exception.dart';
import 'package:meta/meta.dart';

/// The stream of the bytes of a channel: it reads while it is listened to
/// and not paused, and cancels the channel when the listener cancels, which
/// also ends a read that waits.
@internal
final class ChannelStream {
  /// Creates the stream of [_channel].
  ChannelStream(this._channel) {
    _controller
      ..onListen = _start
      ..onPause = _pause
      ..onResume = _resume
      ..onCancel = _cancel;
  }

  /// The channel read.
  final ByteReadChannel _channel;

  /// What hands the chunks to the listener.
  final _controller = StreamController<Uint8List>();

  /// What completes once a paused listener resumes, `null` while it is not
  /// paused.
  Completer<void>? _resumed;

  /// Whether the listener cancelled.
  var _cancelled = false;

  /// Whether the reading ended.
  var _done = false;

  /// The stream to listen to.
  Stream<Uint8List> get stream => _controller.stream;

  /// Starts reading once the stream is listened to.
  void _start() {
    unawaited(_pump());
  }

  /// Holds the reading back while the listener is paused.
  void _pause() {
    _resumed ??= Completer<void>();
  }

  /// Lets the reading go on once the listener resumes.
  void _resume() {
    _resumed?.complete();
    _resumed = null;
  }

  /// Cancels the channel when the listener cancels before the end.
  void _cancel() {
    if (_done) {
      return;
    }
    _cancelled = true;
    _channel.cancel(
      const IoException('The stream of the channel was cancelled'),
    );
    _resume();
  }

  /// Reads the channel into the stream until it ends, fails or the
  /// listener cancels.
  Future<void> _pump() async {
    try {
      while (!_cancelled && !_channel.isClosedForRead) {
        if (_channel.readBuffer.exhausted && !await _channel.awaitContent()) {
          break;
        }
        if (_cancelled) {
          return;
        }
        _controller.add(_channel.readBuffer.readBytes());
        await _resumed?.future;
      }
      final Exception? cause = _channel.closedCause;
      if (cause != null && !_cancelled) {
        _controller.addError(cause);
      }
    } on Object catch (error, stackTrace) {
      if (!_cancelled) {
        _controller.addError(error, stackTrace);
      }
    } finally {
      _done = true;
      if (!_cancelled) {
        await _controller.close();
      }
    }
  }
}
