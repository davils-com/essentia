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

import 'pipeline_config.dart';
import 'pipeline_config_builder.dart';

/// Covers the report of problems from nested builders.
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
