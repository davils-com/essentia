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
import 'package:meta/meta.dart';

/// Watches nothing: a platform without `dart:io` and without a browser
/// tells a program nothing about its end.
///
/// Returns a stream that never emits.
@internal
Stream<ShutdownSignal> watchHostSignals() =>
    const Stream<ShutdownSignal>.empty();

/// Does nothing: the platform does not let a program end itself.
@internal
void exitHost(int code) {}
