/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';
import 'package:test/test.dart';

/// A user principal identified by [id] holding [roles].
Principal _user(String id, [Set<String> roles = const <String>{}]) =>
    Principal.of(id, roles: roles);

/// Ports `PrincipalTest`.
void main() {
  group('roles', () {
    test('answer for a single role', () {
      final Principal caller = _user('auditor', <String>{'reader', 'exporter'});

      expect(caller.hasRole('reader'), isTrue);
      expect(caller.hasRole('writer'), isFalse);
    });

    test('answer whether any of several is held', () {
      final Principal caller = _user('auditor', <String>{'reader'});

      expect(caller.hasAnyRole(<String>['writer', 'reader']), isTrue);
      expect(caller.hasAnyRole(<String>['writer', 'admin']), isFalse);
      expect(caller.hasAnyRole(<String>[]), isFalse);
    });

    test('answer whether all of several are held', () {
      final Principal caller = _user('auditor', <String>{'reader', 'exporter'});

      expect(caller.hasAllRoles(<String>['reader', 'exporter']), isTrue);
      expect(caller.hasAllRoles(<String>['reader', 'writer']), isFalse);
      expect(caller.hasAllRoles(<String>[]), isTrue);
    });
  });

  group('stating one in a single call', () {
    test('defaults to a user with nothing else known', () {
      final caller = Principal.of('alice');

      expect(caller.kind, PrincipalKind.user);
      expect(caller.roles, isEmpty);
      expect(caller.tenant, isNull);
      expect(caller.displayName, isNull);
      expect(caller.attributes, PrincipalAttributes.empty);
      expect(caller.actingFor, isNull);
    });

    test('is equal to another with every field the same, and to nothing '
        'else', () {
      final Principal built = principal('a', (it) {
        it.roles(<String>['y', 'x']);
      });

      expect(_user('a', <String>{'x', 'y'}), built);
      expect(_user('a', <String>{'x', 'y'}).hashCode, built.hashCode);
      expect(_user('a', <String>{'x'}), isNot(_user('a', <String>{'y'})));
      expect(
        Principal.of('a', kind: PrincipalKind.service),
        isNot(Principal.of('a')),
      );
      expect(
        Principal.of('a', tenant: 'acme'),
        isNot(Principal.of('a', tenant: 'globex')),
      );
      expect(Principal.of('a', displayName: 'A'), isNot(Principal.of('a')));
    });

    test('keeps no reference to the set it was given', () {
      final roles = <String>{'reader'};
      final caller = Principal.of('auditor', roles: roles);

      roles.add('writer');

      expect(caller.roles, <String>{'reader'});
    });

    test('its roles refuse to be written through', () {
      final caller = Principal.of('auditor', roles: const <String>{'reader'});

      expect(() => caller.roles.add('writer'), throwsUnsupportedError);
    });
  });

  group('rendering', () {
    test('names every field that is set, roles sorted, sensitive values '
        'masked', () {
      final Principal caller = principal('alice', (it) {
        it
          ..tenant = 'acme'
          ..displayName = 'Alice'
          ..roles(<String>['writer', 'reader'])
          ..attribute('issuer', 'idp')
          ..attribute('email', 'alice@example.invalid', sensitive: true);
      });

      expect(
        caller.toString(),
        'Principal(id=alice, kind=user, tenant=acme, displayName=Alice, '
        'roles=[reader, writer], attributes={email=****, issuer=idp})',
      );
    });

    test('leaves out every field that is not set', () {
      expect(
        Principal.of('nightly-cleanup', kind: PrincipalKind.system).toString(),
        'Principal(id=nightly-cleanup, kind=system)',
      );
    });
  });
}
