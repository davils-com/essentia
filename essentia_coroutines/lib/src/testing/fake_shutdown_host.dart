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

import 'package:essentia_coroutines/src/shutdown/shutdown_host.dart';
import 'package:essentia_coroutines/src/shutdown/shutdown_signal.dart';

/// A host whose signals a test raises and whose ends it records, for
/// `ShutdownHooks` and what is built on it.
///
/// ```dart
/// final host = FakeShutdownHost();
/// final hooks = ShutdownHooks(host: host)..add((signal) => flushed = true);
/// host.raise(ShutdownSignal.terminate);
/// await pumpEventQueue();
/// expect(host.exits, [143]);
/// ```
final class FakeShutdownHost implements ShutdownHost {
  /// Creates a host that nobody watches yet.
  FakeShutdownHost();

  /// The streams handed out by [watch] and still listened to.
  final _watchers = <StreamController<ShutdownSignal>>{};

  /// The exit codes the program asked to end with.
  final _exits = <int>[];

  /// Whether a stream of [watch] is listened to.
  bool get isWatched => _watchers.isNotEmpty;

  /// The exit codes the program asked to end with, in order.
  List<int> get exits => List<int>.unmodifiable(_exits);

  /// Hands out a stream of the signals [raise] sends.
  ///
  /// Returns the stream.
  @override
  Stream<ShutdownSignal> watch() {
    final controller = StreamController<ShutdownSignal>(sync: true);
    controller
      ..onListen = () {
        _watchers.add(controller);
      }
      ..onCancel = () {
        _watchers.remove(controller);
        return controller.close();
      };
    return controller.stream;
  }

  /// Records that the program asked to end with [code].
  @override
  void exit(int code) => _exits.add(code);

  /// Sends [signal] to every stream being listened to.
  ///
  /// A signal that ends the program and that nobody watches does what it
  /// does to a real process by default: the program ends with its exit
  /// code.
  void raise(ShutdownSignal signal) {
    final int? code = signal.exitCode;
    if (_watchers.isEmpty && code != null) {
      _exits.add(code);
      return;
    }
    for (final StreamController<ShutdownSignal> watcher in _watchers.toList()) {
      watcher.add(signal);
    }
  }
}
