/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

@TestOn('vm')
library;

import 'package:inspectra/style.dart';
import 'package:test/test.dart';

import '../../tool/style/no_late_rule.dart';

/// Runs the rule on [source].
///
/// Returns the lines of the violations it reports.
List<int> _lateLines(String source) => <int>[
  for (final StyleViolation violation in const StyleChecker(<StyleRule>[
    NoLateRule(),
  ]).checkSource('lib/sample.dart', source))
    violation.line,
];

/// Tests that the custom style rule refuses every `late` variable.
void main() {
  test('reports a late field, a late top level and a late local', () {
    expect(
      _lateLines('''
late final int top = 1;

class Sample {
  late final int field = 2;
  late int pending;

  void run() {
    late final int local;
    local = 3;
  }
}
'''),
      <int>[1, 4, 5, 8],
    );
  });

  test('accepts variables without late and late as a plain name', () {
    expect(
      _lateLines('''
final int top = 1;

void run() {
  final late = 2;
  final int later = late;
}
'''),
      isEmpty,
    );
  });
}
