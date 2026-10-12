/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/principal/principal.dart';
import 'package:essentia_core/src/principal/principal_kind.dart';
import 'package:essentia_core/src/principal/principal_violation_codes.dart';
import 'package:essentia_core/src/principal/principals.dart';
import 'package:essentia_core/src/validation/validation_exception.dart';
import 'package:essentia_core/src/validation/violation_code.dart';
import 'package:test/test.dart';

/// A value that must never appear in a rendering.
const _placeholder = 'placeholder-value';

/// A user holding the role `reader`.
final _alice = Principal.of('alice', roles: const <String>{'reader'});

/// A service holding the role `service`.
final _indexer = Principal.of(
  'indexer',
  kind: PrincipalKind.service,
  roles: const <String>{'service'},
);

/// A service with no roles.
final _gateway = Principal.of('gateway', kind: PrincipalKind.service);

/// Matches a [ValidationException] whose only error has [code].
Matcher _throwsOnly(ViolationCode code) => throwsA(
  isA<ValidationException>().having(
    (failure) => failure.report.errors.map((error) => error.code).toList(),
    'codes',
    <ViolationCode>[code],
  ),
);

/// A chain of exactly `Principal.maxChainLength` principals, a user at the
/// end and services in front of it.
Principal _longestChain() {
  Principal chain = principal('user-0');
  for (var index = 1; index < Principal.maxChainLength; index++) {
    chain = principal('service-$index').onBehalfOf(chain);
  }
  return chain;
}

/// The ids along the chain of [principal], immediate caller first.
List<String> _ids(Principal principal) =>
    principal.chain.map((link) => link.id).toList();

/// Ports `PrincipalDelegationTest`.
void main() {
  test('a principal acts for nobody unless told to', () {
    expect(_alice.actingFor, isNull);
    expect(_alice.isDelegated, isFalse);
    expect(_alice.originator, _alice);
    expect(_alice.chain, <Principal>[_alice]);
  });

  test('acting on behalf of another keeps both, the immediate caller '
      'first', () {
    final Principal delegated = _indexer.onBehalfOf(_alice);

    expect(delegated.id, 'indexer');
    expect(delegated.actingFor, _alice);
    expect(delegated.isDelegated, isTrue);
    expect(delegated.originator, _alice);
    expect(_ids(delegated), <String>['indexer', 'alice']);
  });

  test('a chain nests, and its originator is who started it', () {
    final Principal delegated = _gateway.onBehalfOf(
      _indexer.onBehalfOf(_alice),
    );

    expect(_ids(delegated), <String>['gateway', 'indexer', 'alice']);
    expect(delegated.originator, _alice);
  });

  test('roles are not inherited along the chain', () {
    final Principal delegated = _indexer.onBehalfOf(_alice);

    expect(delegated.hasRole('reader'), isFalse);
    expect(delegated.hasRole('service'), isTrue);
    expect(delegated.originator.hasRole('reader'), isTrue);
  });

  test('the original principal is left as it was', () {
    _indexer.onBehalfOf(_alice);

    expect(_indexer.actingFor, isNull);
  });

  test('acting on behalf of oneself is refused', () {
    expect(
      () => _alice.onBehalfOf(principal('alice')),
      _throwsOnly(PrincipalViolationCodes.selfDelegation),
    );
  });

  test('the same id in another tenant is another caller and may be acted '
      'for', () {
    final here = Principal.of('alice', tenant: 'acme');
    final there = Principal.of('alice', tenant: 'globex');

    expect(here.onBehalfOf(there).originator, there);
  });

  test('a chain longer than the bound is refused', () {
    final Principal chain = _longestChain();

    expect(
      () => principal('one-too-many').onBehalfOf(chain),
      _throwsOnly(PrincipalViolationCodes.delegationTooDeep),
    );
  });

  test('a chain of exactly the bound is accepted', () {
    expect(_longestChain().chain, hasLength(Principal.maxChainLength));
  });

  test('the rendering names the chain and masks every sensitive attribute '
      'in it', () {
    final Principal user = principal('alice', (it) {
      it.attribute('email', _placeholder, sensitive: true);
    });
    final Principal delegated = _indexer.onBehalfOf(user);

    expect(
      delegated.toString(),
      'Principal(id=indexer, kind=service, roles=[service], '
      'actingFor=Principal(id=alice, kind=user, attributes={email=****}))',
    );
    expect(delegated.toString(), isNot(contains(_placeholder)));
  });

  test('delegation takes part in equality', () {
    expect(_indexer.onBehalfOf(_alice), _indexer.onBehalfOf(_alice));
    expect(
      _indexer.onBehalfOf(_alice).hashCode,
      _indexer.onBehalfOf(_alice).hashCode,
    );
    expect(_indexer.onBehalfOf(_alice), isNot(_indexer));
  });
}
