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

import 'package:test/test.dart';

import 'empty_delimiter_parameters.dart';
import 'split_parameters.dart';

/// No environment at all.
const _nothing = <String, String>{};

/// Tests how a parameter splits its occurrences.
void main() {
  test('an empty delimiter is refused when the parameter is declared', () {
    expect(
      () => EmptyDelimiterParameters().tags,
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.message,
          'message',
          contains('must not be empty'),
        ),
      ),
    );
  });

  test('an empty delimiter is refused on a repeatable parameter as well', () {
    expect(() => EmptyDelimiterParameters().repeated, throwsArgumentError);
  });

  test('a trailing delimiter adds no empty value', () {
    final parameters = SplitParameters()
      ..load(<String>['--tag=a,b,'], environment: _nothing);

    expect(parameters.tags.value, <String>['a', 'b']);
  });

  test('two delimiters in a row add no empty value', () {
    final parameters = SplitParameters()
      ..load(<String>['--tag=a,,b'], environment: _nothing);

    expect(parameters.tags.value, <String>['a', 'b']);
  });

  test('an empty piece is never handed to the converter', () {
    final parameters = SplitParameters()
      ..load(<String>['--port=80,,443,'], environment: _nothing);

    expect(parameters.ports.value, <int>[80, 443]);
  });

  test('the delimiter is matched literally, not as a pattern', () {
    final parameters = SplitParameters()
      ..load(<String>['--word=a.b', '--word=cd'], environment: _nothing);

    expect(parameters.words.value, <String>['a', 'b', 'cd']);
  });
}
