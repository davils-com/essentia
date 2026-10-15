/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

/// The state of encoding one text, chunk by chunk.
@internal
abstract interface class StringEncoding {
  /// Encodes the code units of [chunk] from [start] to [end].
  ///
  /// Returns the bytes; a high surrogate the next chunk may complete is
  /// kept.
  ///
  /// Throws an [ArgumentError] for a character the charset cannot
  /// represent.
  List<int> add(String chunk, int start, int end);

  /// Ends the text.
  ///
  /// Returns the bytes the kept code units encode to.
  List<int> close();
}
