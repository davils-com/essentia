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
import 'many_flag_parameters.dart';

/// No environment at all.
const _nothing = <String, String>{};

/// How long the huge unknown argument is.
const _hugeTokenLength = 1000000;

/// Loads [argv], which holds one unknown argument.
///
/// Returns the violation reporting it.
UnknownArgument _unknownOf(List<String> argv) =>
    singleViolation<UnknownArgument>(
      failureOf(() => ManyFlagParameters().load(argv, environment: _nothing)),
    );

/// Tests that the "did you mean" search stays cheap.
void main() {
  test('a near miss still gets a suggestion', () {
    expect(_unknownOf(<String>['--moed']).suggestion, '--mode');
  });

  test('a near miss of a long name still gets a suggestion', () {
    expect(
      _unknownOf(<String>['--parameter-numbr-2']).suggestion,
      '--parameter-number-2',
    );
  });

  test('an unknown argument far longer than any name gets no suggestion', () {
    expect(
      _unknownOf(<String>['--parameter-number-0-and-a-great-deal-more-text'])
          .suggestion,
      isNull,
    );
  });

  test(
    'a huge unknown argument is reported without searching for a suggestion',
    () {
      final token = '--${'a' * _hugeTokenLength}';

      expect(_unknownOf(<String>[token]).suggestion, isNull);
    },
    timeout: const Timeout(Duration(seconds: 10)),
  );
}
