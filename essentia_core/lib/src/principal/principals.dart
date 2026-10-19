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

import 'package:essentia_core/src/principal/principal.dart';
import 'package:essentia_core/src/principal/principal_builder.dart';
import 'package:essentia_core/src/scope/scope_functions.dart';
import 'package:essentia_core/src/validation/validation_exception.dart';

/// Builds a principal identified by [id] field by field, reporting every
/// problem at once.
///
/// [block] sets the rest - see [PrincipalBuilder]. Left out, the principal
/// is a plain user with nothing else known, which is the short form for a
/// caller with no more than an id:
///
/// ```dart
/// final Principal alice = principal('alice');
/// final Principal indexer = principal('indexer', (it) {
///   it
///     ..kind = PrincipalKind.service
///     ..roles(<String>['reader'])
///     ..actingFor(alice);
/// });
/// ```
///
/// For a user with roles and nothing else, `Principal.of(id, roles: {...})`
/// is the one-call form.
///
/// Returns the principal.
///
/// Throws a [ValidationException] carrying every problem found.
Principal principal(String id, [void Function(PrincipalBuilder it)? block]) =>
    PrincipalBuilder(id).apply(block ?? (_) {}).build();
