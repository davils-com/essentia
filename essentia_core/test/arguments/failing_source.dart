/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';

/// A value source that fails for every parameter, as one whose server
/// refused the connection would.
final class FailingSource implements ValueSource {
  /// Creates the source.
  const FailingSource();

  /// `vault`.
  @override
  String get name => 'vault';

  /// Fails.
  @override
  Future<String?> read(ParameterInfo parameter) =>
      Future<String?>.error(Exception('connection refused'));
}
