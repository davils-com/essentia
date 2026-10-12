/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/bytes/byte_string.dart';
import 'package:meta/meta.dart';

/// Kotlin's `ByteArray.toByteString` on any list of bytes.
extension ByteListToByteString on List<int> {
  /// Copies the bytes into a [ByteString], Kotlin's `toByteString`.
  ///
  /// Returns the byte string.
  @useResult
  ByteString toByteString() => ByteString(this);
}
