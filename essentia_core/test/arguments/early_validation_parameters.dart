/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';

/// A schema that declares validation before the type of its parameter is
/// fixed.
final class EarlyValidationParameters extends Parameters {
  /// Validated as text, then converted.
  final Parameter<int?> port = parameter(<String>['--port'])
      .validate((it, value) {
        if (value.isEmpty) {
          it.fail('empty');
        }
      })
      .integer();

  /// Every parameter above.
  @override
  List<Parameter<Object?>> get declared => <Parameter<Object?>>[port];
}
