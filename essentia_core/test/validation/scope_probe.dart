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
