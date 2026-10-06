/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/principal/principal.dart';
import 'package:essentia/src/principal/principal_builder.dart';
import 'package:essentia/src/scope/scope_functions.dart';
import 'package:essentia/src/validation/validation_exception.dart';

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
