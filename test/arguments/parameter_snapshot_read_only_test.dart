/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
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
