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

import 'package:essentia_core/src/arguments/parameter_exception.dart';
import 'package:essentia_core/src/arguments/parameter_violation.dart';
import 'package:essentia_core/src/version/semantic_version.dart';
import 'package:essentia_core/src/version/semantic_version_range.dart';
import 'package:test/test.dart';

import 'release_parameters.dart';

/// No environment at all.
const _nothing = <String, String>{};

/// Loads [argv] into a new schema, which is expected to fail because of
/// what was passed.
///
/// Returns the [ParameterException] it threw.
///
/// Throws a [StateError] if loading succeeded.
ParameterException _failureOf(List<String> argv) {
  try {
    ReleaseParameters().load(argv, environment: _nothing);
  } on ParameterException catch (failure) {
    return failure;
  }
  throw StateError('Expected a ParameterException, but loading succeeded');
}

/// Tests converting a parameter to a version and to a version range.
void main() {
  test('reads a version and a range', () {
    final parameters = ReleaseParameters()
      ..load(<String>[
        '--version=2.0.0-rc.1',
        '--accepts=^1.2 || ^2',
      ], environment: _nothing);

    expect(
      parameters.version.value,
      SemanticVersion.of(2, preRelease: const <String>['rc', '1']),
    );
    expect(
      parameters.accepts.value,
      SemanticVersionRange.parse('>=1.2.0 <2.0.0-0 || >=2.0.0 <3.0.0-0'),
    );
  });

  test('reports both a malformed version and a malformed range, with the '
      'reason and without the value', () {
    final ParameterException failure = _failureOf(const <String>[
      '--version=v1.02',
      '--accepts=>2 <1',
    ]);

    expect(failure.violations, hasLength(2));
    final List<String> reasons = failure.violations
        .map((violation) => (violation as ConversionFailure).reason)
        .toList();
    expect(reasons, hasLength(2));
    expect(
      reasons.first,
      'is not a semantic version: it must start with three dot-separated '
      'numbers, such as 1.4.0',
    );
    expect(
      reasons.last,
      'is not a version range: it has an alternative that matches no version',
    );
    for (final reason in reasons) {
      expect(reason, isNot(contains('v1.02')));
    }
  });

  test('names the types in the usage listing', () {
    final String usage = ReleaseParameters().usage();

    expect(usage, contains('<version>'));
    expect(usage, contains('<range>'));
  });
}
