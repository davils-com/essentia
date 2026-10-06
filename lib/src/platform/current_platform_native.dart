/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:ffi';

import 'package:essentia/src/platform/platform.dart';
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
