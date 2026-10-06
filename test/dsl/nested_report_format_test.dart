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

import 'pipeline_config.dart';
import 'pipeline_config_builder.dart';

/// Ports `NestedReportFormatTest`.
void main() {
  test('problems from three levels render as one report with the path of '
      'each', () {
    const expected =
        'Invalid configuration (3 problems):\n'
        '\n'
        '  destinations[0].name        is required but was not set\n'
        "  destinations[1].queue.size  '-1' must be greater than zero\n"
        '  destinations                at least one destination must be '
        'configured\n'
        '\n'
        '1 warning:\n'
        '\n'
        '  level  trace on the root logger is expensive in production';

    final ValidationReport report =
        (PipelineConfigBuilder()
              ..level = PipelineConfig.traceLevel
              ..destination((it) => it.name = '')
              ..destination((it) {
                it
                  ..name = 'file'
                  ..async((it) => it.size = -1);
              }))
            .validate();

    expect(report.render(), expected);
  });
}
