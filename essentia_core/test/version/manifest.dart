/*
 * Copyright 2026 Davils
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:essentia_core/essentia_core.dart';
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
