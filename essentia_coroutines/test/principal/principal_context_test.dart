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

import 'dart:async';

import 'package:essentia_core/essentia_core.dart';
import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:test/test.dart';

/// A user principal identified by [id] holding [roles].
Principal _user(String id, [Set<String> roles = const <String>{}]) =>
    Principal.of(id, roles: roles);

/// Emits the id of the current principal once, read when the stream runs.
Stream<String?> _currentIds() async* {
  yield currentPrincipal()?.id;
}

/// Ports the zone part of `PrincipalTest`.
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
}
