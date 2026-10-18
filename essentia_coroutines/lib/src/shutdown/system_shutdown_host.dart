/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/src/shutdown/shutdown_host.dart';
import 'package:essentia_coroutines/src/shutdown/shutdown_platform_stub.dart'
    if (dart.library.io) 'package:essentia_coroutines/src/shutdown/shutdown_platform_io.dart'
    if (dart.library.js_interop) 'package:essentia_coroutines/src/shutdown/shutdown_platform_web.dart';
import 'package:essentia_coroutines/src/shutdown/shutdown_signal.dart';
import 'package:meta/meta.dart';

/// The host the program runs on, `ShutdownHost.system`.
@internal
final class SystemShutdownHost implements ShutdownHost {
  /// Creates the host; there is one, `ShutdownHost.system`.
  const SystemShutdownHost();

  /// Watches the signals of the platform.
  ///
  /// Returns them as they arrive.
  @override
  Stream<ShutdownSignal> watch() => watchHostSignals();

  /// Ends the program with [code] where the platform lets it.
  @override
  void exit(int code) => exitHost(code);
}
