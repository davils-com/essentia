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

import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:test/test.dart';

/// A placeholder standing in for a sensitive value.
const _placeholder = 'placeholder';

/// Tests that the names of a set of headers cannot be changed from outside.
void main() {
  test('the name set refuses to be cleared and the headers are '
      'unchanged', () {
    final EventHeaders headers = EventHeaders.of(const <String, String>{
      'a': '1',
      'b': '2',
    }).withHeader('token', _placeholder, sensitive: true);
    final Set<String> names = headers.names;

    expect(names.clear, throwsUnsupportedError);

    expect(headers.names, unorderedEquals(<String>['a', 'b', 'token']));
    expect(headers['a'], '1');
  });

  test('a sensitive header is still masked after a refused mutation', () {
    final EventHeaders headers = EventHeaders.of(const <String, String>{
      'a': '1',
    }).withHeader('token', _placeholder, sensitive: true);

    expect(() => headers.names.remove('token'), throwsUnsupportedError);

    expect(headers.toString(), '{a=1, token=****}');
  });

  test('headers built by merging refuse a mutation as well', () {
    final EventHeaders merged =
        EventHeaders.of(const <String, String>{'a': '1', 'b': '2'}) +
        EventHeaders.of(const <String, String>{'c': '3', 'd': '4'});

    expect(() => merged.names.add('e'), throwsUnsupportedError);

    expect(merged.names, unorderedEquals(<String>['a', 'b', 'c', 'd']));
  });
}
