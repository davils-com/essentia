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
import 'dart:io';

import 'package:essentia_coroutines/src/shutdown/shutdown_signal.dart';
import 'package:meta/meta.dart';

/// Watches `SIGINT` and, where the platform lets it be watched, `SIGTERM`.
///
/// Returns the signals as they arrive; cancelling the subscription stops
/// watching both.
@internal
Stream<ShutdownSignal> watchHostSignals() {
  final subscriptions = <StreamSubscription<ProcessSignal>>[];
  final controller = StreamController<ShutdownSignal>(sync: true);
  controller
    ..onListen = () {
      subscriptions.add(
        ProcessSignal.sigint.watch().listen(
          (_) => controller.add(ShutdownSignal.interrupt),
        ),
      );
      if (Platform.isWindows) {
        return;
      }
      subscriptions.add(
        ProcessSignal.sigterm.watch().listen(
          (_) => controller.add(ShutdownSignal.terminate),
        ),
      );
    }
    ..onCancel = () async {
      await Future.wait<void>(subscriptions.map((it) => it.cancel()));
      await controller.close();
    };
  return controller.stream;
}

/// Ends the process with [code].
@internal
void exitHost(int code) => exit(code);
