/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';
import 'package:test/test.dart';

import 'manifest.dart';

/// Tests that a malformed version or range joins the report of a
/// validation instead of ending it.
void main() {
  test('a well-formed version and range add nothing to the report', () {
    final ValidationReport report = const Manifest(
      '1.4.0',
      '[1.2, 2.0)',
      'plugin',
    ).validateAs('manifest');

    expect(report.violations, isEmpty);
  });

  test('a malformed version and range join the report beside every other '
      'problem', () {
    final ValidationReport report = const Manifest(
      'v1.4',
      '>=',
      '',
    ).validateAs('manifest');

    expect(report.errors.map((error) => error.path.toString()), <String>[
      'version',
      'requiresShell',
      'name',
    ]);
    expect(report.errors.map((error) => error.code), <ViolationCode>[
      VersionViolationCodes.invalidVersion,
      VersionViolationCodes.invalidRange,
      report.errors.last.code,
    ]);
  });

  test('a range in npm notation is read as well', () {
    final ValidationReport report = const Manifest(
      '1.4.0',
      '^1.2 || ^2',
      'plugin',
    ).validateAs('manifest');

    expect(report.violations, isEmpty);
  });

  test('the message says why', () {
    final ValidationReport report = const Manifest(
      '1.4.0',
      '[2.0, 1.0)',
      'plugin',
    ).validateAs('manifest');

    expect(
      report.errors.single.message,
      'is not a version range: it has an interval that is empty, because its '
      'lower bound is not below its upper',
    );
  });
}
