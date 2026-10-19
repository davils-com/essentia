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

import 'package:essentia_core/src/text/string_similarity.dart';
import 'package:test/test.dart';

/// The names a mistyped name is compared against.
const _declared = <String>['--port', '--host', 'name', 'tags', 'queueSize'];

/// Covers the bounded "did you mean" search.
void main() {
  test('finds the name that was meant', () {
    final List<String?> found = <String>[
      '--prot',
      '--hots',
      'tagz',
      'queuesize',
    ].map((token) => token.closestIn(_declared)).toList();

    expect(found, <String?>['--port', '--host', 'tags', 'queueSize']);
  });

  test('finds nothing when no name is close enough', () {
    const token = 'completely-different';

    final String? found = token.closestIn(_declared);

    expect(found, isNull);
  });

  test('allows one edit for every three characters', () {
    const token = 'nmae';

    final String? found = token.closestIn(_declared);

    expect(found, isNull);
  });

  test('allows no more than three edits however long the name is', () {
    const candidate = 'averyveryverylongparametername';
    const fourEdits = 'xxxxveryveryverylongparametername';

    final String? found = fourEdits.closestIn(<String>[candidate]);

    expect(found, isNull);
  });

  test('suggests nothing for a name shorter than three characters', () {
    const token = 'nm';

    final String? found = token.closestIn(<String>['n']);

    expect(found, isNull);
  });

  test('does not compare a token longer than 64 characters', () {
    final String token = 'a' * 65;

    final String? found = token.closestIn(<String>['${'a' * 64}b']);

    expect(found, isNull);
  });

  test('prefers the closer of two candidates', () {
    const token = 'abcdef';

    final String? found = token.closestIn(<String>['abxxef', 'abcdxf']);

    expect(found, 'abcdxf');
  });

  test('keeps the first of two equally close candidates', () {
    const token = 'abcdef';

    final String? found = token.closestIn(<String>['abcdxf', 'abcdey']);

    expect(found, 'abcdxf');
  });
}
