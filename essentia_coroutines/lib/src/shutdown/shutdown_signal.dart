/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// What the host tells a program about its end.
enum ShutdownSignal {
  /// `SIGINT`, sent by Ctrl-C in a terminal; a shell gives a process ended
  /// by it the exit code 130.
  interrupt(130),

  /// `SIGTERM`, sent by a service manager or a container runtime that
  /// stops the program; a shell gives a process ended by it the exit code
  /// 143.
  terminate(143),

  /// The page being hidden in a browser, the last moment a browser reliably
  /// gives a page. The page may come back, so it ends nothing.
  pageHide(null);

  /// Creates the signal with its [exitCode].
  const ShutdownSignal(this.exitCode);

  /// The exit code of a process ended by this signal, or `null` for a
  /// signal that does not end the program.
  final int? exitCode;

  /// Whether this signal ends the program.
  bool get endsProgram => exitCode != null;
}
