/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';

/// Measures a name, a use case with nothing behind it.
final class NameLength implements UseCase<String, int> {
  /// Creates the use case.
  const NameLength();

  /// Measures [input].
  @override
  Future<int> call(String input) => Future<int>.value(input.length);
}
