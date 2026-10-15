/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

/// Thrown by a `BrotliBitReader` that holds too few bytes for a read while
/// more may still come: the decoder goes back to where the step it was
/// taking began and takes it again once more bytes are there.
@internal
final class BrotliInputNeeded implements Exception {
  /// Creates the signal, [brotliInputNeeded].
  const BrotliInputNeeded._();

  /// Says what the signal means.
  ///
  /// Returns the text.
  @override
  String toString() => 'BrotliInputNeeded';
}

/// The one signal of too few bytes.
@internal
const brotliInputNeeded = BrotliInputNeeded._();
