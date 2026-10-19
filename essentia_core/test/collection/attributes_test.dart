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

/// The key of a number in the tests.
const _count = AttributeKey<int>('Count');

/// The key of a text in the tests.
const _name = AttributeKey<String>('Name');

/// Tests the typed attributes and their keys.
void main() {
  test('hands out the value stored under a key', () {
    final attributes = Attributes()..put(_count, 3);

    final int value = attributes.get(_count);

    expect(value, 3);
    expect(attributes.contains(_count), isTrue);
    expect(attributes.contains(_name), isFalse);
  });

  test('replaces the value under a key', () {
    final attributes = Attributes()
      ..put(_count, 1)
      ..put(_count, 2);

    expect(attributes.get(_count), 2);
    expect(attributes.allKeys, [_count]);
  });

  test('refuses to hand out a missing value', () {
    final attributes = Attributes();

    expect(
      () => attributes.get(_count),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'No instance for key AttributeKey: Count',
        ),
      ),
    );
    expect(attributes.getOrNull(_count), isNull);
  });

  test('finds a value under an equal key created elsewhere', () {
    final attributes = Attributes()..put(_count, 7);

    expect(attributes.get(const AttributeKey<int>('Count')), 7);
    expect(attributes.contains(const AttributeKey<String>('Count')), isFalse);
  });

  test('removes a value', () {
    final attributes = Attributes()
      ..put(_count, 1)
      ..remove(_count)
      ..remove(_name);

    expect(attributes.contains(_count), isFalse);
    expect(attributes.allKeys, isEmpty);
  });

  test('takes a value out', () {
    final attributes = Attributes()..put(_name, 'vectia');

    final String taken = attributes.take(_name);

    expect(taken, 'vectia');
    expect(attributes.contains(_name), isFalse);
    expect(() => attributes.take(_name), throwsStateError);
    expect(attributes.takeOrNull(_name), isNull);
  });

  test('takes a value out if there is one', () {
    final attributes = Attributes()..put(_count, 5);

    final int? taken = attributes.takeOrNull(_count);

    expect(taken, 5);
    expect(attributes.contains(_count), isFalse);
  });

  test('creates a missing value once', () {
    final attributes = Attributes();
    var created = 0;

    final int first = attributes.computeIfAbsent(_count, () => ++created);
    final int second = attributes.computeIfAbsent(_count, () => ++created);

    expect(first, 1);
    expect(second, 1);
    expect(created, 1);
  });

  test('copies the values of other attributes', () {
    final other = Attributes()
      ..put(_count, 2)
      ..put(_name, 'b');
    final attributes = Attributes()
      ..put(_name, 'a')
      ..putAll(other);

    expect(attributes.get(_count), 2);
    expect(attributes.get(_name), 'b');
    expect(attributes.allKeys, [_name, _count]);
  });

  test('refuses a value of another type through a widened key', () {
    const AttributeKey<Object> widened = _count;
    final attributes = Attributes();

    expect(() => attributes.put(widened, 'text'), throwsArgumentError);
    expect(attributes.contains(_count), isFalse);
  });

  test('hands out its keys as a list that cannot change it', () {
    final attributes = Attributes()..put(_count, 1);

    expect(() => attributes.allKeys.add(_name), throwsUnsupportedError);
  });

  test('compares keys by name and type', () {
    expect(const AttributeKey<int>('a'), const AttributeKey<int>('a'));
    expect(
      const AttributeKey<int>('a').hashCode,
      const AttributeKey<int>('a').hashCode,
    );
    expect(const AttributeKey<int>('a'), isNot(const AttributeKey<int>('b')));
    expect(const AttributeKey<int>('a'), isNot(const AttributeKey<num>('a')));
    expect(_count.type, int);
    expect(_count.toString(), 'AttributeKey: Count');
  });
}
