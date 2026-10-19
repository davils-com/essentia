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

import 'package:essentia_core/src/platform/platform.dart';
import 'package:meta/meta.dart';

/// Whether this program was compiled to WebAssembly rather than to
/// JavaScript, where an integer and a double of the same value are one and
/// the same number.
const bool _isWasm = !identical(0, 0.0);

/// Reads the platform of a web runtime.
///
/// Returns the web on WebAssembly, or `null` for a program compiled to
/// JavaScript, which runs on no architecture Essentia can name.
@internal
Platform? currentPlatform() {
  if (_isWasm) {
    return Platform.of('web', 'wasm');
  }
  return null;
}
