/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/result/result.dart';

/// Collapses a result that carries a result.
extension ResultFlatten<T> on Result<Result<T>> {
  /// Collapses the nested result into one, like Kotlin's `flatten` on
  /// nested collections.
  ///
  /// Returns the inner result of a success, or the outer failure.
  Result<T> flatten() => flatMap((nested) => nested);
}
