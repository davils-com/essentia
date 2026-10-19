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

import 'package:essentia_core/src/dsl/validating_builder.dart';
import 'package:essentia_core/src/principal/principal.dart';
import 'package:essentia_core/src/principal/principal_attributes.dart';
import 'package:essentia_core/src/principal/principal_kind.dart';
import 'package:essentia_core/src/principal/principal_violation_codes.dart';
import 'package:essentia_core/src/text/string_blankness.dart';
import 'package:essentia_core/src/validation/validation_scope.dart';
import 'package:essentia_core/src/validation/violation_path.dart';
import 'package:meta/meta.dart';

/// Assembles a [Principal] from what an edge knows about the caller,
/// reporting every problem at once.
///
/// ```dart
/// final Principal caller = principal(token.subject, (it) {
///   it
///     ..kind = PrincipalKind.user
///     ..tenant = token.tenant
///     ..displayName = token.name
///     ..roles(token.roles)
///     ..attribute('email', token.email, sensitive: true);
/// });
/// ```
///
/// A principal is usually built from a token or a request - several fields,
/// several ways to be wrong - and a blank tenant beside a blank role is two
/// findings, not one.
final class PrincipalBuilder extends ValidatingBuilder<Principal> {
  /// Creates a builder for the principal identified by [_id].
  @internal
  PrincipalBuilder(this._id);

  /// What identifies the caller.
  final String _id;

  /// The roles added so far.
  final _heldRoles = <String>{};

  /// The attributes set so far.
  PrincipalAttributes _attributes = PrincipalAttributes.empty;

  /// Whom the caller acts for, or `null`.
  Principal? _delegate;

  /// What sort of caller this is. [PrincipalKind.user] unless said
  /// otherwise.
  PrincipalKind kind = PrincipalKind.user;

  /// The tenant the caller acts in, or `null` where there is only one.
  String? tenant;

  /// A name for a person reading an audit trail.
  String? displayName;

  /// What a report about this builder is headed with.
  @override
  String get subject => 'principal';

  /// Adds [names] to the roles the caller holds.
  void roles(Iterable<String> names) {
    _heldRoles.addAll(names);
  }

  /// Sets the attribute [name] to [value].
  ///
  /// [sensitive] masks the value wherever Essentia renders it. A blank
  /// [name] is reported under `attributes` rather than thrown.
  void attribute(String name, String value, {bool sensitive = false}) {
    if (name.isBlank) {
      final scope =
          ValidationScope(
            ViolationPath.root,
            PrincipalViolationCodes.invalidAttribute,
          )..fail(
            'must not have a blank name',
            code: PrincipalViolationCodes.invalidAttribute,
          );
      adopt(scope.violations(), ViolationPath.of('attributes'));
      return;
    }
    _attributes = _attributes.withAttribute(name, value, sensitive: sensitive);
  }

  /// Makes the caller act on behalf of [principal].
  void actingFor(Principal principal) {
    _delegate = principal;
  }

  /// Puts the principal together from what was configured, unchecked.
  @override
  Principal assemble() => Principal.assembled(
    _id,
    kind,
    _heldRoles,
    tenant,
    displayName,
    _attributes,
    _delegate,
  );
}
