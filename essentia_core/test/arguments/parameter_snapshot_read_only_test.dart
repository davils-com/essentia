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

import 'tagged_parameters.dart';

/// No environment at all.
const _nothing = <String, String>{};

/// Tests that nothing a load hands out can be written to.
void main() {
  test("a repeated parameter's values refuse a write", () {
    final parameters = TaggedParameters()
      ..load(<String>['--tag', 'a', '--tag', 'b'], environment: _nothing);

    expect(() => parameters.tags.value.add('injected'), throwsUnsupportedError);
    expect(parameters.tags.value, <String>['a', 'b']);
  });

  test("a repeated parameter's default refuses a write", () {
    final parameters = TaggedParameters()
      ..load(const <String>[], environment: _nothing);

    expect(parameters.ports.value.clear, throwsUnsupportedError);
    expect(parameters.ports.value, <int>[80, 443]);
  });

  test('the arguments after the terminator refuse a write', () {
    final parameters = TaggedParameters()
      ..load(<String>['--', 'one', 'two'], environment: _nothing);

    expect(parameters.rest.clear, throwsUnsupportedError);
    expect(parameters.rest, <String>['one', 'two']);
  });

  test('the collected unknown arguments refuse a write', () {
    final parameters = TaggedParameters()
      ..load(<String>['--one', '--two'], environment: _nothing);

    expect(parameters.unknown.clear, throwsUnsupportedError);
    expect(parameters.unknown, <String>['--one', '--two']);
  });

  test('the warnings refuse a write', () {
    final parameters = TaggedParameters()
      ..load(<String>['--legacy'], environment: _nothing);

    expect(parameters.warnings.clear, throwsUnsupportedError);
    expect(parameters.warnings, hasLength(1));
  });
}
