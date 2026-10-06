/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';
import 'package:meta/meta.dart';

/// A plugin manifest that carries its version and the shell versions it
/// requires as text, and states its own invariants.
@immutable
final class Manifest implements Validatable {
  /// Creates the manifest of the plugin [name], at [version], requiring a
  /// shell in [requiresShell].
  const Manifest(this.version, this.requiresShell, this.name);

  /// The version of the plugin, as written.
  final String version;

  /// The shell versions the plugin requires, as written.
  final String requiresShell;

  /// The name of the plugin.
  final String name;

  /// States what is wrong with the manifest.
  @override
  void validate(ValidationScope scope) {
    scope
      ..semanticVersion(version, property: 'version')
      ..semanticVersionRange(requiresShell, property: 'requiresShell');
    if (name.trim().isEmpty) {
      scope.fail('is required but was not set', property: 'name');
    }
  }
}
