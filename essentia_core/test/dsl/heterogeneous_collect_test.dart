/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';
import 'package:test/test.dart';

import 'destination_data.dart';
import 'pipeline_data.dart';
import 'pipeline_data_builder.dart';

/// Builds the pipeline [block] describes.
PipelineData _pipeline(void Function(PipelineDataBuilder it) block) =>
    PipelineDataBuilder().apply(block).build();

/// Matches a [ValidationException] whose message contains every one of
/// [parts].
Matcher _throwsMentioning(List<String> parts) => throwsA(
  isA<ValidationException>().having(
    (failure) => failure.message,
    'message',
    allOf(parts.map(contains).toList()),
  ),
);

/// Covers builders of different subtypes collected into one list.
void main() {
  test('builders producing different subtypes fill one list of the '
      'supertype', () {
    final PipelineData data = _pipeline((it) {
      it
        ..console((it) => it.colour = false)
        ..file((it) => it.maxBytes = 4096);
    });

    expect(data.destinations, <DestinationData>[
      const ConsoleData('console', colour: false),
      const FileData('file', 4096),
    ]);
  });

  test('each element reports under its own index, whichever builder '
      'produced it', () {
    expect(
      () => _pipeline((it) {
        it
          ..console((it) => it.name = '')
          ..file((it) => it.maxBytes = 0);
      }),
      _throwsMentioning(<String>[
        'destinations[0].name',
        'destinations[1].maxBytes',
      ]),
    );
  });

  test('the index counts declared blocks, so a valid one after an invalid '
      'one keeps its position', () {
    expect(
      () => _pipeline((it) {
        it
          ..console((it) => it.name = '')
          ..file((it) => it.name = 'kept')
          ..file((it) => it.maxBytes = -1);
      }),
      _throwsMentioning(<String>[
        'destinations[0].name',
        'destinations[2].maxBytes',
      ]),
    );
  });

  test('a block that failed is not appended', () {
    expect(
      () => _pipeline((it) {
        it
          ..console()
          ..file((it) => it.maxBytes = 0);
      }),
      throwsA(
        isA<ValidationException>().having(
          (failure) => failure.report.violations,
          'violations',
          hasLength(1),
        ),
      ),
    );
  });

  test('only the failed block reports, at the index it was declared at '
      'among blocks of other builders', () {
    final ValidationReport report =
        (PipelineDataBuilder()
              ..file((it) => it.maxBytes = 0)
              ..console()
              ..file((it) => it.name = 'kept'))
            .validate();

    expect(report.violations, hasLength(1));
    expect(
      report.violations.single.path.toString(),
      'destinations[0].maxBytes',
    );
  });

  test('the enclosing value is still validated alongside its elements', () {
    expect(
      () => _pipeline((_) {}),
      _throwsMentioning(<String>['destinations', 'at least one destination']),
    );
  });
}
