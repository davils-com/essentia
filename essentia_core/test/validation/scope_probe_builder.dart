/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';

import 'scope_probe.dart';

/// Assembles a [ScopeProbe], so that a scope test reads its report the way
/// a configuration builder does.
final class ScopeProbeBuilder extends ValidatingBuilder<ScopeProbe> {
  /// Creates the builder of a probe running [_rules].
  ScopeProbeBuilder(this._rules);

  /// The rules the assembled probe runs.
  final void Function(ValidationScope it) _rules;

  /// Assembles the probe.
  @override
  ScopeProbe assemble() => ScopeProbe(_rules);
}
