/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
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
