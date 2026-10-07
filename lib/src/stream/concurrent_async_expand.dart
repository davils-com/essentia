/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia/src/stream/subscription_cancel.dart';
import 'package:meta/meta.dart';

/// Maps every element of [source] to an inner stream with [convert] and
/// merges all inner streams concurrently, like `asyncExpand` without
/// waiting for one inner stream to end before the next one starts.
///
/// Events are emitted in the order the inner streams emit them, which may
/// differ from the order of [source]. Errors of [source], of [convert] and
/// of the inner streams are passed on without ending the result. The
/// result ends once [source] and every inner stream have ended.
///
/// Pause and resume reach [source] and every running inner stream, and
/// cancelling the result cancels all of them.
///
/// Returns a stream that is a broadcast stream exactly when [source] is; a
/// broadcast result shares one subscription of [source] between all of its
/// listeners.
@internal
Stream<S> concurrentAsyncExpand<T, S>(
  Stream<T> source,
  Stream<S> Function(T element) convert,
) {
  final bool broadcast = source.isBroadcast;
  final controller = broadcast
      ? StreamController<S>.broadcast(sync: true)
      : StreamController<S>(sync: true);
  controller.onListen = () {
    final subscriptions = <StreamSubscription<Object?>>[];

    void track(StreamSubscription<Object?> subscription) {
      subscription.onDone(() {
        subscriptions.remove(subscription);
        if (subscriptions.isEmpty) {
          unawaited(controller.close());
        }
      });
      subscriptions.add(subscription);
    }

    final StreamSubscription<T> outer =
        source.listen(null, onError: controller.addError)..onData((element) {
          final Stream<S> inner;
          try {
            inner = convert(element);
          } on Object catch (error, stackTrace) {
            controller.addError(error, stackTrace);
            return;
          }
          track(inner.listen(controller.add, onError: controller.addError));
        });
    track(outer);
    if (!broadcast) {
      controller
        ..onPause = () {
          for (final subscription in subscriptions) {
            subscription.pause();
          }
        }
        ..onResume = () {
          for (final subscription in subscriptions) {
            subscription.resume();
          }
        };
    }
    controller.onCancel = () {
      if (subscriptions.isEmpty) {
        return null;
      }
      return <Future<void>>[
        for (final subscription in subscriptions)
          keepInZone(subscription.cancel()),
      ].wait.then((_) {});
    };
  };
  return controller.stream;
}
