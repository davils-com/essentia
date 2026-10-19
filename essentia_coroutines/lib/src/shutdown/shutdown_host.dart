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
