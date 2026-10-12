/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';

import 'console.dart';

/// Produces a console for a name, a use case whose output is a subtype.
final class ConsoleByName implements UseCase<String, Console> {
  /// Creates the use case.
  const ConsoleByName();

  /// Produces the coloured console [input].
  @override
  Future<Console> call(String input) =>
      Future<Console>.value(Console(input, colour: true));
}
