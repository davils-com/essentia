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

import 'package:essentia_core/src/text/string_words.dart';
import 'package:test/test.dart';

/// Names and their snake case.
const _snakeCase = <String, String>{
  '': '',
  'name': 'name',
  'camelCase': 'camel_case',
  'retryAfterSeconds': 'retry_after_seconds',
  'PascalCase': 'pascal_case',
  'HTTPServer': 'http_server',
  'URLMapping': 'url_mapping',
  'someURL': 'some_url',
  'URLs': 'ur_ls',
  'ID': 'id',
  'userID': 'user_id',
  'a1B': 'a1_b',
  'version2Name': 'version2_name',
  'already_snake': 'already_snake',
  '_leading': '_leading',
  'snake_Case': 'snake_case',
  'Über': 'über',
  'grüßeAnDich': 'grüße_an_dich',
};

/// Names and their words.
const _words = <String, List<String>>{
  '': <String>[],
  'name': <String>['name'],
  'camelCase': <String>['camel', 'Case'],
  'HTTPServer': <String>['HTTP', 'Server'],
  'someURL': <String>['some', 'URL'],
  'lease_duration': <String>['lease', 'duration'],
  'kubernetes-kubeconfig': <String>['kubernetes', 'kubeconfig'],
  'HTTP server': <String>['HTTP', 'server'],
  '__a__b__': <String>['a', 'b'],
  'version2Name': <String>['version2', 'Name'],
  'RETRY_AFTER': <String>['RETRY', 'AFTER'],
};

/// Covers splitting names into words and the spellings built from them.
void main() {
  for (final MapEntry<String, String>(:key, :value) in _snakeCase.entries) {
    test('spells "$key" in snake case as "$value"', () {
      final String spelled = key.toSnakeCase();

      expect(spelled, value);
    });
  }

  for (final MapEntry<String, List<String>>(:key, :value) in _words.entries) {
    test('splits "$key" into $value', () {
      final List<String> words = key.words();

      expect(words, value);
    });
  }

  test('spells kebab case with the snake case algorithm', () {
    const name = 'kubernetesKubeconfig';

    final String spelled = name.toKebabCase();

    expect(spelled, 'kubernetes-kubeconfig');
  });

  test('spells kebab case without doubling an existing dash', () {
    const name = 'ftp-Site';

    final String spelled = name.toKebabCase();

    expect(spelled, 'ftp-site');
  });

  test('spells screaming snake case', () {
    const name = 'retryAfterSeconds';

    final String spelled = name.toScreamingSnakeCase();

    expect(spelled, 'RETRY_AFTER_SECONDS');
  });

  test('spells camel case from any spelling', () {
    final List<String> spelled = <String>[
      'lease_duration',
      'kubernetes-kubeconfig',
      'HTTP server',
      'RETRY_AFTER',
      'PascalCase',
    ].map((name) => name.toCamelCase()).toList();

    expect(spelled, <String>[
      'leaseDuration',
      'kubernetesKubeconfig',
      'httpServer',
      'retryAfter',
      'pascalCase',
    ]);
  });

  test('spells pascal case from any spelling', () {
    final List<String> spelled = <String>[
      'lease_duration',
      'someURL',
      'retryAfter',
    ].map((name) => name.toPascalCase()).toList();

    expect(spelled, <String>['LeaseDuration', 'SomeUrl', 'RetryAfter']);
  });

  test('spells nothing as nothing', () {
    const name = '';

    expect(name.toCamelCase(), '');
    expect(name.toPascalCase(), '');
  });

  test('the words are unmodifiable', () {
    final List<String> words = 'camelCase'.words();

    expect(() => words.add('more'), throwsUnsupportedError);
  });
}
