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

/// Tests the map whose keys compare without regard to case.
void main() {
  test('finds a value under any spelling of its key', () {
    final map = CaseInsensitiveMap<String>()..['Content-Type'] = 'text/plain';

    expect(map['content-type'], 'text/plain');
    expect(map['CONTENT-TYPE'], 'text/plain');
    expect(map.containsKey('Content-type'), isTrue);
    expect(map.containsKey('Accept'), isFalse);
  });

  test('keeps the first spelling and the last value', () {
    final map = CaseInsensitiveMap<int>()
      ..['ETag'] = 1
      ..['etag'] = 2;

    expect(map.keys, ['ETag']);
    expect(map['ETAG'], 2);
    expect(map, hasLength(1));
  });

  test('keeps the order keys were first stored in', () {
    final map = CaseInsensitiveMap<int>()
      ..['b'] = 1
      ..['A'] = 2
      ..['B'] = 3;

    expect(map.keys, ['b', 'A']);
    expect(map.values, [3, 2]);
  });

  test('removes an entry under any spelling', () {
    final map = CaseInsensitiveMap<int>()..['Host'] = 1;

    final int? removed = map.remove('HOST');

    expect(removed, 1);
    expect(map, isEmpty);
    expect(map.remove('host'), isNull);
  });

  test('answers a key that is no string with nothing', () {
    final map = CaseInsensitiveMap<int>()..['1'] = 1;
    const Object number = 1;

    expect(map[number], isNull);
    expect(map.containsKey(number), isFalse);
    expect(map.remove(number), isNull);
    expect(map, hasLength(1));
  });

  test('copies another map, joining keys that differ in case', () {
    final map = CaseInsensitiveMap<int>.of({
      'Accept': 1,
      'accept': 2,
      'Host': 3,
    });

    expect(map.keys, ['Accept', 'Host']);
    expect(map['ACCEPT'], 2);
  });

  test('forgets every entry on clear', () {
    final map = CaseInsensitiveMap<int>()
      ..['a'] = 1
      ..clear();

    expect(map, isEmpty);
    expect(map['a'], isNull);
  });

  test('keeps a stored null apart from a missing key', () {
    final map = CaseInsensitiveMap<int?>()..['Empty'] = null;

    expect(map.containsKey('empty'), isTrue);
    expect(map['empty'], isNull);
    expect(map.length, 1);
  });
}
