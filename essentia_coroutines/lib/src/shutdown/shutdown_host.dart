/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/src/shutdown/shutdown_signal.dart';
import 'package:essentia_coroutines/src/shutdown/system_shutdown_host.dart';

/// What a program learns from its host about its end, and how it ends
/// itself.
///
/// [system] is the host the program runs on; a test hands `ShutdownHooks`
/// a `FakeShutdownHost` of `package:essentia_coroutines/testing.dart`
/// instead.
abstract interface class ShutdownHost {
  /// The host the program runs on: `SIGINT` and, except on Windows,
  /// `SIGTERM` where `dart:io` is, the page being hidden in a browser, and
  /// nothing elsewhere.
  static const ShutdownHost system = SystemShutdownHost();

  /// Starts watching the signals of the host.
  ///
  /// Watching a signal of a process replaces what the process does on it
  /// by default, which is to end: while the stream is listened to, the
  /// program has to end itself. Cancelling the subscription restores the
  /// default.
  ///
  /// Returns the signals as they arrive.
  Stream<ShutdownSignal> watch();

  /// Ends the program with [code] where the host lets a program end itself,
  /// and does nothing where it does not, as in a browser.
  void exit(int code);
}
