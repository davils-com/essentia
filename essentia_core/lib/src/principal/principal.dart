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

import 'package:essentia_core/src/principal/principal_attributes.dart';
import 'package:essentia_core/src/principal/principal_kind.dart';
import 'package:essentia_core/src/principal/principal_violation_codes.dart';
import 'package:essentia_core/src/text/string_blankness.dart';
import 'package:essentia_core/src/validation/validatable.dart';
import 'package:essentia_core/src/validation/validatable_checks.dart';
import 'package:essentia_core/src/validation/validation_exception.dart';
import 'package:essentia_core/src/validation/validation_scope.dart';
import 'package:meta/meta.dart';

/// Who is asking, carried in the current `Zone`.
///
/// A request-scoped identity propagates the way a zone does - through
/// `await`, `Future`, `Timer`, microtasks and stream listeners created
/// inside it - so code several calls down can name the caller without every
/// signature in between carrying a parameter for it:
///
/// ```dart
/// final Principal caller = principal('alice', (it) {
///   it
///     ..tenant = 'acme'
///     ..roles(<String>['reader'])
///     ..attribute('email', 'alice@example.invalid', sensitive: true);
/// });
///
/// await runAsPrincipal(caller, () async {
///   await files.readText(path);
/// });
/// ```
///
/// Inside the body `currentPrincipal()` answers alice, however deep.
///
/// ## What it carries
///
/// An [id], a [kind], the [roles] it holds, optionally the [tenant] it acts
/// in and a [displayName], the [attributes] of the token that established
/// it, and - when it acts for somebody else - the principal it [actingFor].
/// See [onBehalfOf] for delegation.
///
/// ## What it is not
///
/// **Not authorisation.** It names the caller and lists its roles; what a
/// role permits is decided by whoever owns the resource, with whatever model
/// suits it. A type every Davils library shares must not pick one model of
/// permission for all of them. [hasRole] answers for this principal alone
/// and never for one it acts for.
///
/// **Not authentication.** A principal is exactly as trustworthy as the code
/// that put it into the zone. Put one there at the edge that verified the
/// caller - a login, a checked token, the process's own startup - and
/// nowhere deeper.
///
/// ## Rendering
///
/// A principal is the object that ends up in a log line, so [toString]
/// masks every sensitive attribute, including those of the principal it
/// acts for. Two principals are equal when every field is, delegation
/// included.
@immutable
final class Principal implements Validatable {
  /// Creates a principal from its fields, without checking any of them.
  const Principal._(
    this.id,
    this.kind,
    this.roles,
    this.tenant,
    this.displayName,
    this.attributes,
    this.actingFor,
  );

  /// States a principal in one call.
  ///
  /// The builder, `principal(id, (it) { ... })`, is the form for anything
  /// with more than two fields.
  ///
  /// [id] identifies the caller, [kind] says what sort of caller it is,
  /// [roles] are the roles it holds, [tenant] is the tenant it acts in or
  /// `null`, [displayName] is a name for a person to read or `null`,
  /// [attributes] is what else is known about it, and [actingFor] is whom
  /// it acts on behalf of or `null`. The roles are copied, so changing the
  /// set afterwards does not change the principal.
  ///
  /// Throws a [ValidationException] carrying every problem with the values
  /// given, rather than only the first.
  factory Principal.of(
    String id, {
    PrincipalKind kind = PrincipalKind.user,
    Set<String> roles = const <String>{},
    String? tenant,
    String? displayName,
    PrincipalAttributes attributes = PrincipalAttributes.empty,
    Principal? actingFor,
  }) => Principal.assembled(
    id,
    kind,
    roles,
    tenant,
    displayName,
    attributes,
    actingFor,
  ).validateOrThrow(_subject);

  /// Puts a principal together from its fields without validating it,
  /// copying [roles] so the caller keeps no handle on them.
  ///
  /// Only the builder uses this, because it validates as part of its own
  /// report.
  @internal
  factory Principal.assembled(
    String id,
    PrincipalKind kind,
    Iterable<String> roles,
    String? tenant,
    String? displayName,
    PrincipalAttributes attributes,
    Principal? actingFor,
  ) => Principal._(
    id,
    kind,
    Set<String>.unmodifiable(roles),
    tenant,
    displayName,
    attributes,
    actingFor,
  );

  /// The longest delegation chain a principal may head, itself included.
  ///
  /// Real chains are two or three long - a gateway, a service, the user. The
  /// bound exists so a loop in calling code that wraps the current principal
  /// again on every pass fails at once instead of building a chain nobody
  /// can read.
  static const maxChainLength = 8;

  /// What a validation report about a principal is headed with.
  static const _subject = 'principal';

  /// What identifies the caller - a user name, a service account, a token's
  /// subject.
  final String id;

  /// What sort of caller this is.
  final PrincipalKind kind;

  /// The roles the caller holds. What each one permits is the resource
  /// owner's decision.
  final Set<String> roles;

  /// The tenant the caller acts in, or `null` where there is only one.
  final String? tenant;

  /// A name for a person reading an audit trail, or `null` when there is
  /// none beyond [id].
  final String? displayName;

  /// What else is known about the caller, with sensitive values masked in
  /// every rendering.
  final PrincipalAttributes attributes;

  /// The principal this one acts on behalf of, or `null` when it acts for
  /// itself.
  final Principal? actingFor;

  /// This principal and every one it acts for, in order: the immediate
  /// caller first, the one who started it all last.
  List<Principal> get chain {
    final links = <Principal>[];
    Principal? current = this;
    while (current != null) {
      links.add(current);
      current = current.actingFor;
    }
    return List<Principal>.unmodifiable(links);
  }

  /// The principal the chain started with - the user a chain of services is
  /// ultimately working for. This principal itself when it acts for nobody.
  Principal get originator => chain.last;

  /// Whether this principal acts on behalf of another one.
  bool get isDelegated => actingFor != null;

  /// Whether this principal holds [role], matched exactly. Roles of a
  /// principal it acts for do not count.
  ///
  /// Returns `true` when [roles] contains it.
  bool hasRole(String role) => roles.contains(role);

  /// Whether this principal holds at least one of [roles].
  ///
  /// Returns `true` when any of them is held; `false` when none are, or
  /// none were given.
  bool hasAnyRole(Iterable<String> roles) => roles.any(hasRole);

  /// Whether this principal holds every one of [roles].
  ///
  /// Returns `true` when all of them are held, which includes when none
  /// were given.
  bool hasAllRoles(Iterable<String> roles) => roles.every(hasRole);

  /// This principal, acting on behalf of [principal].
  ///
  /// The shape of a service calling another service for a user: the service
  /// is the immediate caller and the user is who it works for, and an audit
  /// record needs both. A chain nests - a principal that already acts for
  /// somebody keeps that when it is itself acted for.
  ///
  /// ```dart
  /// await runAsPrincipal(indexer.onBehalfOf(requirePrincipal()), () async {
  ///   await documents.reindex(folder);
  /// });
  /// ```
  ///
  /// Returns a new principal, identical to this one but acting for
  /// [principal]. This one is left as it was.
  ///
  /// Throws a [ValidationException] if [principal] is this caller itself,
  /// or the resulting chain is longer than [maxChainLength].
  Principal onBehalfOf(Principal principal) => Principal._(
    id,
    kind,
    roles,
    tenant,
    displayName,
    attributes,
    principal,
  ).validateOrThrow(_subject);

  /// States what is wrong with this principal, reporting through [scope].
  @override
  void validate(ValidationScope scope) {
    if (id.isBlank) {
      scope.fail(
        'must not be blank',
        property: 'id',
        code: PrincipalViolationCodes.blankId,
      );
    }
    if (roles.any((role) => role.isBlank)) {
      scope.fail(
        'must not contain a blank role',
        property: 'roles',
        code: PrincipalViolationCodes.blankRole,
      );
    }
    if (tenant?.isBlank ?? false) {
      scope.fail(
        'must not be blank when set',
        property: 'tenant',
        code: PrincipalViolationCodes.blankTenant,
      );
    }
    if (displayName?.isBlank ?? false) {
      scope.fail(
        'must not be blank when set',
        property: 'displayName',
        code: PrincipalViolationCodes.blankDisplayName,
      );
    }
    _validateDelegation(scope);
  }

  /// Two principals are equal when every field is, delegation included.
  @override
  bool operator ==(Object other) =>
      other is Principal &&
      _isSameCaller(other) &&
      _sameRoles(other.roles) &&
      displayName == other.displayName &&
      attributes == other.attributes &&
      actingFor == other.actingFor;

  /// The hash of every field, delegation included.
  @override
  int get hashCode => Object.hash(
    id,
    kind,
    tenant,
    Object.hashAllUnordered(roles),
    displayName,
    attributes,
    actingFor,
  );

  /// Renders the principal with every sensitive attribute masked, its own
  /// and those of every principal it acts for:
  /// `Principal(id=alice, kind=user, tenant=acme, roles=[reader])`.
  @override
  String toString() {
    final Principal? delegate = actingFor;
    final List<String> sortedRoles = roles.toList()..sort();
    final parts = <String>[
      'id=$id',
      'kind=${kind.name}',
      if (tenant != null) 'tenant=$tenant',
      if (displayName != null) 'displayName=$displayName',
      if (roles.isNotEmpty) 'roles=$sortedRoles',
      if (!attributes.isEmpty) 'attributes=$attributes',
      if (delegate != null) 'actingFor=$delegate',
    ];
    return 'Principal(${parts.join(', ')})';
  }

  /// Reports a delegation to this caller itself, and a chain longer than
  /// [maxChainLength], through [scope].
  void _validateDelegation(ValidationScope scope) {
    final Principal? delegate = actingFor;
    if (delegate == null) {
      return;
    }
    if (_isSameCaller(delegate)) {
      scope.fail(
        'must not be the principal itself',
        property: 'actingFor',
        code: PrincipalViolationCodes.selfDelegation,
      );
    }
    final int length = chain.length;
    if (length > maxChainLength) {
      scope.fail(
        'makes a chain of $length principals, and at most $maxChainLength '
        'are allowed',
        property: 'actingFor',
        code: PrincipalViolationCodes.delegationTooDeep,
      );
    }
  }

  /// Whether [other] names the same caller: the same id, kind and tenant.
  ///
  /// Returns `true` when all three match.
  bool _isSameCaller(Principal other) =>
      id == other.id && kind == other.kind && tenant == other.tenant;

  /// Whether [others] holds exactly the roles of this principal.
  ///
  /// Returns `true` when both hold the same roles, in any order.
  bool _sameRoles(Set<String> others) =>
      others.length == roles.length && roles.containsAll(others);
}
