/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';
import 'dart:collection';

import 'package:essentia/src/channels/buffer_overflow.dart';
import 'package:essentia/src/stream/subscription_cancel.dart';

/// The capacity of `Channel.buffered`, Kotlin's
/// `CHANNEL_DEFAULT_CAPACITY`.
const _defaultCapacity = 64;

/// The capacity that asks for conflation, Kotlin's `Channel.CONFLATED`.
const _conflated = -1;

/// The capacity that asks for the default buffer, Kotlin's
/// `Channel.BUFFERED`.
const _buffered = -2;

/// Kotlin's buffering `Flow` operators for streams.
extension StreamBuffering<T> on Stream<T> {
  /// Lets this stream run ahead of a slow listener by up to [capacity]
  /// elements, Kotlin's `buffer`.
  ///
  /// This stream is listened to on its own pace: elements the listener
  /// cannot take yet, because it is paused - `await for` pauses while its
  /// body runs - wait in the buffer. Once [capacity] elements wait,
  /// [onBufferOverflow] decides: [BufferOverflow.suspend] pauses this
  /// stream until the listener took one, [BufferOverflow.dropOldest] drops
  /// the oldest waiting element and [BufferOverflow.dropLatest] the new
  /// one. [capacity] is a count, `-2` for the default of 64 (Kotlin's
  /// `Channel.BUFFERED`) or `-1` for conflation (Kotlin's
  /// `Channel.CONFLATED`, see [conflate]). As in Kotlin, a dropping buffer
  /// of zero or the default capacity holds one element.
  ///
  /// Errors keep their place among the elements and are never dropped. The
  /// result ends once this stream ended and the buffer is empty. Cancel
  /// reaches this stream.
  ///
  /// ```dart
  /// await numbers.buffer(64).collect((value) async {
  ///   await delay(300.milliseconds);
  ///   print(value);
  /// });
  /// ```
  ///
  /// Returns a single subscription stream; every listener gets its own
  /// subscription of this stream and its own buffer.
  ///
  /// Throws an [ArgumentError] if [capacity] is negative but neither `-1`
  /// nor `-2`, or if it is `-1` while [onBufferOverflow] is not
  /// [BufferOverflow.suspend].
  Stream<T> buffer(
    int capacity, {
    BufferOverflow onBufferOverflow = BufferOverflow.suspend,
  }) {
    if (capacity < 0 && capacity != _buffered && capacity != _conflated) {
      throw ArgumentError(
        'Buffer size should be non-negative, BUFFERED, or CONFLATED, but was '
            '$capacity',
        'capacity',
      );
    }
    if (capacity == _conflated && onBufferOverflow != BufferOverflow.suspend) {
      throw ArgumentError(
        'CONFLATED capacity cannot be used with non-default onBufferOverflow',
        'onBufferOverflow',
      );
    }
    if (capacity == _conflated) {
      return _buffer(1, BufferOverflow.dropOldest);
    }
    if (onBufferOverflow == BufferOverflow.suspend) {
      return _buffer(
        capacity == _buffered ? _defaultCapacity : capacity,
        onBufferOverflow,
      );
    }
    return _buffer(
      capacity == _buffered || capacity == 0 ? 1 : capacity,
      onBufferOverflow,
    );
  }

  /// Keeps only the latest element while the listener is busy, Kotlin's
  /// `conflate`.
  ///
  /// The listener gets the elements it is ready for and, after a pause,
  /// the latest element that arrived meanwhile; the ones in between are
  /// dropped. It is `buffer(-1)`.
  ///
  /// Returns a single subscription stream.
  Stream<T> conflate() => buffer(_conflated);

  /// Buffers up to [capacity] elements, overflowing as [overflow] says.
  ///
  /// Returns the buffered stream.
  Stream<T> _buffer(int capacity, BufferOverflow overflow) => Stream<T>.multi((
    controller,
  ) {
    final Zone zone = Zone.current;
    final events = Queue<({bool isValue, void Function() deliver})>();
    var values = 0;
    var done = false;
    var holding = false;
    final StreamSubscription<T> upstream = listen(null);

    void drain() {
      while (events.isNotEmpty && !controller.isPaused) {
        final ({bool isValue, void Function() deliver}) event = events
            .removeFirst();
        if (event.isValue) {
          values--;
        }
        event.deliver();
      }
      if (holding && values <= capacity) {
        holding = false;
        upstream.resume();
      }
      if (done && events.isEmpty && !controller.isClosed) {
        controller.closeSync();
      }
    }

    upstream
      ..onData((value) {
        drain();
        if (values >= capacity) {
          switch (overflow) {
            case BufferOverflow.suspend:
              if (!holding) {
                holding = true;
                upstream.pause();
              }
            case BufferOverflow.dropLatest:
              return;
            case BufferOverflow.dropOldest:
              events.remove(events.firstWhere((event) => event.isValue));
              values--;
          }
        }
        events.add((isValue: true, deliver: () => controller.addSync(value)));
        values++;
        drain();
      })
      ..onError((Object error, StackTrace stackTrace) {
        events.add((
          isValue: false,
          deliver: () => controller.addErrorSync(error, stackTrace),
        ));
        drain();
      })
      ..onDone(() {
        done = true;
        drain();
      });
    controller
      ..onResume = () {
        zone.scheduleMicrotask(drain);
      }
      ..onCancel = () => keepInZone(upstream.cancel());
  });
}
