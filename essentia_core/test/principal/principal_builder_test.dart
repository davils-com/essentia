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
import 'package:essentia_core/src/principal/principal_kind.dart';
import 'package:essentia_core/src/principal/principal_violation_codes.dart';
import 'package:essentia_core/src/principal/principals.dart';
import 'package:essentia_core/src/validation/validation_exception.dart';
import 'package:essentia_core/src/validation/validation_report.dart';
import 'package:essentia_core/src/validation/violation_code.dart';
import 'package:test/test.dart';

/// A value that must never appear in a rendering.
const _placeholder = 'placeholder-value';

/// Matches a [ValidationException] whose report satisfies [matcher].
Matcher _throwsReport(Matcher matcher) => throwsA(
  isA<ValidationException>().having(
    (failure) => failure.report,
    'report',
    matcher,
  ),
);

/// The rendered paths of the errors in [report], in order.
List<String> _paths(ValidationReport report) =>
    report.errors.map((violation) => violation.path.toString()).toList();

/// The codes of the errors in [report], in order.
List<ViolationCode> _codes(ValidationReport report) =>
    report.errors.map((violation) => violation.code).toList();

/// Covers building a principal and the violations its builder reports.
void main() {
  test('builds a principal with every field set', () {
    final Principal alice = principal('alice');
    final Principal caller = principal('indexer', (it) {
      it
        ..kind = PrincipalKind.service
        ..tenant = 'acme'
        ..displayName = 'Search indexer'
        ..roles(<String>['reader', 'exporter'])
        ..attribute('issuer', 'idp')
        ..attribute('token', _placeholder, sensitive: true)
        ..actingFor(alice);
    });

    expect(caller.kind, PrincipalKind.service);
    expect(caller.tenant, 'acme');
    expect(caller.displayName, 'Search indexer');
    expect(caller.roles, <String>{'reader', 'exporter'});
    expect(caller.attributes['issuer'], 'idp');
    expect(caller.attributes.isSensitive('token'), isTrue);
    expect(caller.actingFor, alice);
  });

  test('a builder with nothing set is a plain user', () {
    expect(principal('alice', (it) {}), Principal.of('alice'));
    expect(principal('alice'), Principal.of('alice'));
  });

  test('reports every problem at once, each under the field it is '
      'about', () {
    expect(
      () => principal(' ', (it) {
        it
          ..tenant = ''
          ..displayName = ' '
          ..roles(<String>['reader', ''])
          ..attribute('', 'x');
      }),
      _throwsReport(
        isA<ValidationReport>()
            .having(_paths, 'paths', <String>[
              'attributes',
              'id',
              'roles',
              'tenant',
              'displayName',
            ])
            .having(_codes, 'codes', <ViolationCode>[
              PrincipalViolationCodes.invalidAttribute,
              PrincipalViolationCodes.blankId,
              PrincipalViolationCodes.blankRole,
              PrincipalViolationCodes.blankTenant,
              PrincipalViolationCodes.blankDisplayName,
            ]),
      ),
    );
  });

  test('refuses acting for itself as a violation rather than a throw from '
      'inside the block', () {
    expect(
      () => principal('alice', (it) => it.actingFor(principal('alice'))),
      _throwsReport(
        isA<ValidationReport>().having(_codes, 'codes', <ViolationCode>[
          PrincipalViolationCodes.selfDelegation,
        ]),
      ),
    );
  });

  test('the single-call form reports every problem at once too', () {
    expect(
      () => Principal.of('', roles: const <String>{' '}, tenant: ''),
      _throwsReport(
        isA<ValidationReport>().having(
          (report) => report.errors,
          'errors',
          hasLength(3),
        ),
      ),
    );
  });

  test('a report names the subject', () {
    expect(
      () => principal(''),
      _throwsReport(
        isA<ValidationReport>().having(
          (report) => report.subject,
          'subject',
          'principal',
        ),
      ),
    );
  });
}
