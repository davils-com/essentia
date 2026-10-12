/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
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
