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

import 'package:essentia_coroutines/src/flow/shared_flow.dart';

/// A shared flow that holds one current [value].
///
/// A new listener gets the current value first and then every change.
/// Changes are conflated: a listener that is slow, or paused, skips the
/// values it missed and gets only the latest one, and a value equal (`==`)
/// to the one it got before is never delivered again.
abstract interface class StateFlow<T> implements SharedFlow<T> {
  /// The current value.
  T get value;
}
