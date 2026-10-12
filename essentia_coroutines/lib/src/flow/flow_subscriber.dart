/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia_core/essentia_core.dart';
import 'package:essentia_coroutines/src/exception/cancellation_exception.dart';
import 'package:essentia_coroutines/src/stream/cancellation_watch.dart';
import 'package:meta/meta.dart';

/// Delivers the values of a hot flow to one listener, one at a time and
/// only while the listener is not paused.
///
/// The pump runs as a microtask in the zone the listener subscribed in,
/// never inside the call that made a value available, so a listener that
/// emits back into its flow cannot disturb the delivery. A value is taken
/// only right before it is delivered, so a paused listener holds its place
/// in the flow. When the job the listener subscribed in is cancelled, the
/// listener gets the `CancellationException` of the job and is done.
@internal
final class FlowSubscriber<T> {
  /// Creates the subscriber feeding [_controller], taking values with
  /// [_take] and handing its place back with [_release] once it ends.
  FlowSubscriber(this._controller, this._take, this._release);

  /// The controller of the listener.
  final MultiStreamController<T> _controller;

  /// Takes the next value, or returns `null` when there is none yet.
  final ({T value})? Function() _take;

  /// Hands the place of the listener in the flow back.
  final void Function() _release;

  /// The zone the listener subscribed in, where the pump runs.
  final Zone _zone = Zone.current;

  /// Whether a pump is queued.
  var _scheduled = false;

  /// Whether the listener is still subscribed.
  var _active = true;

  /// Watches the job the listener subscribed in.
  Disposable? _watch;

  /// Hooks the subscriber up to its controller and to the job of the
  /// current code, and queues the first pump.
  void start() {
    _controller
      ..onResume = wake
      ..onCancel = () {
        _end();
        return Future<void>.value();
      };
    _watch = watchCancellation(_cancelled);
    wake();
  }

  /// Queues a pump, unless one is queued already or the listener left.
  void wake() {
    if (_scheduled || !_active) {
      return;
    }
    _scheduled = true;
    _zone.scheduleMicrotask(_pump);
  }

  /// Delivers values while there are some and the listener takes them.
  void _pump() {
    _scheduled = false;
    while (_active && !_controller.isPaused) {
      final ({T value})? next = _take();
      if (next == null) {
        return;
      }
      _controller.addSync(next.value);
    }
  }

  /// Ends the listener with [cause] because its job was cancelled.
  void _cancelled(CancellationException cause) {
    if (!_active) {
      return;
    }
    _end();
    _controller.addError(cause);
    unawaited(_controller.close());
  }

  /// Hands the place of the listener back, once.
  void _end() {
    if (!_active) {
      return;
    }
    _active = false;
    _watch?.dispose();
    _watch = null;
    _release();
  }
}
