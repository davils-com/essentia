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

import 'failure_of.dart';
import 'quoting_rule_parameters.dart';

/// No environment at all.
const _nothing = <String, String>{};

/// A value that must never reach the report.
const _placeholder = 'placeholder-not-a-token';

/// Loads a secret that fails its rule.
///
/// Returns the failure.
ParameterException _secretFailure() => failureOf(
  () => QuotingRuleParameters().load(<String>[
    '--token=$_placeholder',
  ], environment: _nothing),
);

/// Tests that a rule on a sensitive parameter cannot put the value in the
/// report.
void main() {
  test('a rule that quotes a sensitive value does not put it in the '
      'report', () {
    expect(_secretFailure().toString(), isNot(contains(_placeholder)));
  });

  test("a sensitive parameter's failed rule is reported with a fixed "
      'message and its code', () {
    final ValidationFailure violation = singleViolation<ValidationFailure>(
      _secretFailure(),
    );

    expect(
      violation.message,
      'failed validation - the detail is withheld because the parameter is '
      'sensitive',
    );
    expect(violation.code, ParameterViolationCodes.validationFailed);
  });

  test("the rule's own words stay reachable for a caller who wants them", () {
    final ValidationFailure violation = singleViolation<ValidationFailure>(
      _secretFailure(),
    );

    expect(violation.detail, "'$_placeholder' is not a valid token");
  });

  test("a parameter that is not sensitive is reported in the rule's own "
      'words', () {
    final ValidationFailure violation = singleViolation<ValidationFailure>(
      failureOf(
        () => QuotingRuleParameters().load(<String>[
          '--name=ab',
        ], environment: _nothing),
      ),
    );

    expect(violation.message, "'ab' is too short");
    expect(violation.detail, "'ab' is too short");
  });
}
