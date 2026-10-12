/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';

/// A value whose invariants are whatever rules a scope test hands it.
final class ScopeProbe implements Validatable {
  /// Creates the probe that reports through [_rules].
  const ScopeProbe(this._rules);

  /// The rules run against the scope.
  final void Function(ValidationScope it) _rules;

  /// Runs the rules against [scope].
  @override
  void validate(ValidationScope scope) => _rules(scope);
}
