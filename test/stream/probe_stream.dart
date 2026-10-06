/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

/// A stream source that records what its listener does to it: `listen`,
/// `pause`, `resume` and `cancel`, in order.
final class ProbeStream<T> {
  /// Creates a single subscription probe.
  ///
  /// [onCancel] runs after `cancel` was recorded, and the cancel of the
  /// listener waits for the future it returns.
  ProbeStream({Future<void> Function()? onCancel}) {
    controller = StreamController<T>(
      onListen: () => log.add('listen'),
      onPause: () => log.add('pause'),
      onResume: () => log.add('resume'),
      onCancel: () {
        log.add('cancel');
        return onCancel?.call();
      },
    );
  }

  /// Creates a broadcast probe, which records `listen` for its first
  /// listener and `cancel` once its last listener left.
  ProbeStream.broadcast() {
    controller = StreamController<T>.broadcast(
      onListen: () => log.add('listen'),
      onCancel: () => log.add('cancel'),
    );
  }

  /// What the listeners did, in order.
  final log = <String>[];

  /// The controller feeding the probe.
  late final StreamController<T> controller;

  /// The stream to hand to the operator under test.
  Stream<T> get stream => controller.stream;

  /// Emits [values] and ends the stream.
  ///
  /// Returns a future that completes once the stream ended.
  Future<void> emitAll(Iterable<T> values) async {
    values.forEach(controller.add);
    await controller.close();
  }
}

/// Lets every pending microtask and zero delay timer run.
///
/// Returns a future that completes after them.
Future<void> settle() => Future<void>.delayed(Duration.zero);

/// Listens to the stream that [operate] builds on top of [probe], pauses,
/// resumes and cancels the subscription, settling after every step.
///
/// Returns the log of [probe].
Future<List<String>> lifecycleOf<T>(
  ProbeStream<T> probe,
  Stream<Object?> Function(Stream<T> source) operate,
) async {
  final StreamSubscription<Object?> subscription = operate(probe.stream)
      .listen(null);
  await settle();
  subscription.pause();
  await settle();
  subscription.resume();
  await settle();
  await subscription.cancel();
  return probe.log;
}
