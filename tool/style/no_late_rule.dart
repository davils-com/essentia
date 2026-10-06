/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:inspectra/style.dart';

import 'late_visitor.dart';

/// `no_late`: no `late` variable anywhere, so that no read can fail with
/// a `LateInitializationError` and every value is there once its owner
/// exists.
final class NoLateRule extends StyleRule {
  /// Creates the rule.
  const NoLateRule();

  /// The rule id.
  @override
  String get id => 'no_late';

  /// What the rule requires.
  @override
  String get description =>
      'No late variables: initialise every variable where it is declared.';

  /// Reports every `late`.
  @override
  void check(StyleFile file, StyleReporter reporter) =>
      file.unit.accept(LateVisitor(reporter));
}
