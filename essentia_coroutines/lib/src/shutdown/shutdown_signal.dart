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
