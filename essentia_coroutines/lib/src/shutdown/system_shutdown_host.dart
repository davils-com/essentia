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
