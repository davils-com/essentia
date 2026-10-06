/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia/src/principal/principal.dart';
import 'package:essentia/src/principal/principal_attributes.dart';
import 'package:essentia/src/principal/principal_context.dart';
import 'package:essentia/src/principal/principal_kind.dart';
import 'package:essentia/src/principal/principal_missing_exception.dart';
import 'package:essentia/src/principal/principals.dart';
import 'package:test/test.dart';

/// A user principal identified by [id] holding [roles].
Principal _user(String id, [Set<String> roles = const <String>{}]) =>
    Principal.of(id, roles: roles);

/// Emits the id of the current principal once, read when the stream runs.
Stream<String?> _currentIds() async* {
  yield currentPrincipal()?.id;
}

/// Ports `PrincipalTest`.
void main() {
  group('in a zone', () {
    test('is absent until somebody puts it there', () {
      expect(currentPrincipal(), isNull);
    });

    test('is what the enclosing runAsPrincipal put there', () {
      final Principal? seen = runAsPrincipal(
        _user('auditor', <String>{'reader'}),
        currentPrincipal,
      );

      expect(seen, _user('auditor', <String>{'reader'}));
    });

    test('reaches a future started inside it', () async {
      final String? seen = await runAsPrincipal(
        _user('auditor'),
        () => Future<String?>(() => currentPrincipal()?.id),
      );

      expect(seen, 'auditor');
    });

    test('reaches a microtask scheduled inside it', () async {
      final seen = Completer<String?>();

      runAsPrincipal(_user('auditor'), () {
        scheduleMicrotask(() => seen.complete(currentPrincipal()?.id));
      });

      expect(await seen.future, 'auditor');
    });

    test('reaches a stream listened to inside it', () async {
      final List<String?> seen = await runAsPrincipal(
        _user('auditor'),
        () => _currentIds().toList(),
      );

      expect(seen, <String?>['auditor']);
    });

    test('survives an await inside its body', () async {
      final String? seen = await runAsPrincipal(_user('auditor'), () async {
        await Future<void>.delayed(Duration.zero);
        return currentPrincipal()?.id;
      });

      expect(seen, 'auditor');
    });

    test('an inner one replaces the outer one for its body only', () {
      runAsPrincipal(_user('outer'), () {
        final String? inner = runAsPrincipal(
          _user('inner'),
          () => currentPrincipal()?.id,
        );

        expect(inner, 'inner');
        expect(currentPrincipal()?.id, 'outer');
      });
    });

    test('is gone once its body is done', () async {
      await runAsPrincipal(_user('auditor'), () async {
        await Future<void>.delayed(Duration.zero);
      });

      expect(currentPrincipal(), isNull);
    });
  });

  group('requiring one', () {
    test('answers the principal in the zone', () {
      final Principal seen = runAsPrincipal(_user('auditor'), requirePrincipal);

      expect(seen.id, 'auditor');
    });

    test('throws a dedicated exception naming the fix when there is '
        'none', () {
      expect(
        requirePrincipal,
        throwsA(
          isA<PrincipalMissingException>()
              .having((failure) => failure, 'exception', isA<Exception>())
              .having(
                (failure) => failure.message,
                'message',
                contains('runAsPrincipal(principal(...)'),
              ),
        ),
      );
    });
  });

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
