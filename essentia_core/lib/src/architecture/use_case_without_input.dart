/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/architecture/use_case.dart';

/// Runs a use case that needs no input without passing `null` for it.
extension UseCaseWithoutInput<O> on UseCase<void, O> {
  /// Runs the use case, so that it is called as `report.invoke()` rather
  /// than `report(null)`.
  ///
  /// Returns what the use case produced.
  Future<O> invoke() => call(null);
}
