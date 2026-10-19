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

import 'dart:ffi';

import 'package:essentia_core/src/platform/platform.dart';
import 'package:meta/meta.dart';

/// Reads the platform of the native runtime from its application binary
/// interface, which the Dart VM reports as `linux_x64` or `macos_arm64`.
///
/// Returns the platform, or `null` if the machine is one Essentia cannot
/// name.
@internal
Platform? currentPlatform() {
  final abi = Abi.current().toString();
  final int separator = abi.indexOf('_');
  if (separator < 0) {
    return null;
  }
  return Platform.of(abi.substring(0, separator), abi.substring(separator + 1));
}
