/*
 * Copyright 2026 Davils
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:async';

/// A stream source that records what its listener does to it: `listen`,
/// `pause`, `resume` and `cancel`, in order.
final class ProbeStream<T> {
  /// Creates a single subscription probe.
  ///
  /// [onCancel] runs after `cancel` was recorded, and the cancel of the
  /// listener waits for the future it returns.
  factory ProbeStream({Future<void> Function()? onCancel}) {
    final log = <String>[];
    return ProbeStream._(
      log,
      StreamController<T>(
        onListen: () => log.add('listen'),
        onPause: () => log.add('pause'),
        onResume: () => log.add('resume'),
        onCancel: () {
          log.add('cancel');
          return onCancel?.call();
        },
      ),
    );
  }

  /// Creates a broadcast probe, which records `listen` for its first
  /// listener and `cancel` once its last listener left.
  factory ProbeStream.broadcast() {
    final log = <String>[];
    return ProbeStream._(
      log,
      StreamController<T>.broadcast(
        onListen: () => log.add('listen'),
        onCancel: () => log.add('cancel'),
      ),
    );
  }

  /// Creates a probe recording into [log] what is done to [controller].
  ProbeStream._(this.log, this.controller);

  /// What the listeners did, in order.
  final List<String> log;

  /// The controller feeding the probe.
  final StreamController<T> controller;

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
