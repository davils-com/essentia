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

import 'package:essentia_core/src/collection/map_transformation.dart';
import 'package:test/test.dart';

/// Ports by protocol.
const _ports = <String, int>{'http': 80, 'https': 443, 'ssh': 22};

/// Covers transforming and filtering the entries of a map.
void main() {
  test('transforms the keys and keeps the values', () {
    final Map<String, int> upper = _ports.mapKeys(
      (key, _) => key.toUpperCase(),
    );

    expect(upper, <String, int>{'HTTP': 80, 'HTTPS': 443, 'SSH': 22});
  });

  test('keeps the last value when transformed keys collide', () {
    final Map<int, int> byLength = _ports.mapKeys((key, _) => key.length);

    expect(byLength, <int, int>{4: 80, 5: 443, 3: 22});
  });

  test('transforms the values and keeps the keys', () {
    final Map<String, String> described = _ports.mapValues(
      (key, value) => '$key:$value',
    );

    expect(described['ssh'], 'ssh:22');
  });

  test('keeps only the present transformation results', () {
    final List<String> secure = _ports.mapNotNull(
      (key, value) => value > 100 ? key : null,
    );

    expect(secure, <String>['https']);
  });

  test('keeps the entries that match', () {
    final Map<String, int> low = _ports.where((_, value) => value < 100);

    expect(low, <String, int>{'http': 80, 'ssh': 22});
  });

  test('keeps the entries that do not match', () {
    final Map<String, int> high = _ports.whereNot((_, value) => value < 100);

    expect(high, <String, int>{'https': 443});
  });

  test('keeps the entries whose key matches', () {
    final Map<String, int> web = _ports.whereKeys(
      (key) => key.startsWith('http'),
    );

    expect(web.keys, <String>['http', 'https']);
  });

  test('keeps the entries whose value matches', () {
    final Map<String, int> even = _ports.whereValues((value) => value.isEven);

    expect(even.keys, <String>['http', 'ssh']);
  });

  test('turns its entries into records', () {
    final List<(String, int)> records = _ports.toRecords();

    expect(records, <(String, int)>[('http', 80), ('https', 443), ('ssh', 22)]);
  });

  test('hands out a transformed map that cannot be modified', () {
    final Map<String, int> low = _ports.where((_, value) => value < 100);

    void modify() => low['ftp'] = 21;

    expect(modify, throwsUnsupportedError);
  });
}
