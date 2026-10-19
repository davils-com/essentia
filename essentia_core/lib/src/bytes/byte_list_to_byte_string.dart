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

/// Turns any list of bytes into a [ByteString].
extension ByteListToByteString on List<int> {
  /// Copies the bytes into a [ByteString].
  ///
  /// Returns the byte string.
  @useResult
  ByteString toByteString() => ByteString(this);
}
