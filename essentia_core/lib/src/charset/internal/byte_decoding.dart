/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

/// The state of decoding one sequence of bytes, chunk by chunk.
@internal
abstract interface class ByteDecoding {
  /// Decodes the bytes of [chunk] from [start] to [end].
  ///
  /// Returns the text they complete; bytes that start a character the
  /// next chunk ends are kept.
  String add(List<int> chunk, int start, int end);

  /// Ends the sequence.
  ///
  /// Returns what the kept bytes decode to: a replacement character for
  /// an incomplete one.
  String close();
}
