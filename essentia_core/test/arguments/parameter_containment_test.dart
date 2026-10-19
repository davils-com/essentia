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
import 'package:test/test.dart';

import 'careless_parameters.dart';
import 'failing_source.dart';
import 'failure_of.dart';
import 'fake_vault.dart';
import 'sourced_parameters.dart';

/// No environment at all.
const _nothing = <String, String>{};

/// A value that must never reach the report.
const _placeholder = 'placeholder-secret-value';

/// Tests that a converter or a value source that throws is reported with
/// everything else instead of ending the load.
void main() {
  group('a converter that throws something other than a '
      'ConversionException', () {
    test('is reported as a conversion failure beside every other problem', () {
      final ParameterException failure = failureOf(
        () => CarelessParameters().load(<String>[
          '--port=eighty',
          '--workers=many',
        ], environment: _nothing),
      );

      expect(
        failure.violations.map((violation) => violation.code),
        <ViolationCode>[
          ParameterViolationCodes.conversionFailed,
          ParameterViolationCodes.conversionFailed,
        ],
      );
    });

    test('is reported with a generic reason and keeps what it threw as the '
        'cause', () {
      final ConversionFailure violation = singleViolation<ConversionFailure>(
        failureOf(
          () => CarelessParameters().load(<String>[
            '--port=eighty',
          ], environment: _nothing),
        ),
      );

      expect(violation.reason, 'could not be read as port');
      expect(violation.cause, isA<FormatException>());
    });

    test('does not leak a sensitive value through its own message', () {
      final ParameterException failure = failureOf(
        () => CarelessParameters().load(<String>[
          '--pin=$_placeholder',
        ], environment: _nothing),
      );

      expect(failure.toString(), isNot(contains(_placeholder)));
    });

    test('a ConversionException keeps its own reason and is the cause', () {
      final ConversionFailure violation = singleViolation<ConversionFailure>(
        failureOf(
          () => CarelessParameters().load(<String>[
            '--workers=many',
          ], environment: _nothing),
        ),
      );

      expect(violation.reason, 'is not a valid integer');
      expect(violation.cause, isA<ConversionException>());
      final Causal causal = violation;
      expect(causal.cause, same(violation.cause));
      expect(causal.causeStackTrace, isNull);
    });
  });

  group('a value source that throws', () {
    test('is reported as unavailable instead of ending the load', () async {
      final ParameterException failure = await failureOfAsync(
        () => SourcedParameters().loadFrom(const <String>[], <ValueSource>[
          const FailingSource(),
        ], environment: _nothing),
      );

      expect(
        failure.violations.map((violation) => violation.code).toSet(),
        <ViolationCode>{ParameterViolationCodes.sourceUnavailable},
      );
    });

    test("is reported under the source's name with the exception kept but "
        'not rendered', () async {
      final ParameterException failure = await failureOfAsync(
        () => SourcedParameters().loadFrom(const <String>[], <ValueSource>[
          const FailingSource(),
        ], environment: _nothing),
      );

      final SourceUnavailable violation = failure.violations
          .whereType<SourceUnavailable>()
          .first;
      expect(violation.path.toString(), '--token (from vault)');
      expect(violation.sourceName, 'vault');
      expect(violation.message, 'could not be read, because the source failed');
      expect('${violation.cause}', contains('connection refused'));
      final Causal causal = violation;
      expect(causal.cause, same(violation.cause));
      expect(causal.causeStackTrace, isNull);
      expect(failure.toString(), isNot(contains('connection refused')));
    });

    test('does not stop a later source from being asked', () async {
      final answering = FakeVault(<String, String>{
        '--token': 'north',
        '--region': 'north',
      }, name: 'defaults');

      final ParameterException failure = await failureOfAsync(
        () => SourcedParameters().loadFrom(const <String>[], <ValueSource>[
          const FailingSource(),
          answering,
        ], environment: _nothing),
      );

      expect(answering.asked, <String>['--token', '--region']);
      final Iterable<ConversionFailure> conversions = failure.violations
          .whereType<ConversionFailure>();
      expect(conversions.single.path.toString(), '--region (from defaults)');
    });
  });
}
