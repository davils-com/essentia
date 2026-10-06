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
