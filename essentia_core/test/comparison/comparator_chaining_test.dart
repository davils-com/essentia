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

import 'package:essentia_core/src/comparison/comparator_chaining.dart';
import 'package:essentia_core/src/comparison/comparison_dsl.dart';
import 'package:test/test.dart';

import 'person.dart';

/// Ada, as old as Bob.
const Person _ada = (name: 'Ada', age: 36);

/// Bob, as old as Ada.
const Person _bob = (name: 'Bob', age: 36);

/// Cid, younger than Ada and Bob.
const Person _cid = (name: 'Cid', age: 20);

/// Covers breaking the ties of a comparator with further keys.
void main() {
  test('breaks ties by the next key ascending', () {
    final people = <Person>[_bob, _cid, _ada];

    final sorted = List<Person>.of(people)
      ..sort(
        compareByDescending<Person, num>((person) => person.age)
            .thenBy((person) => person.name),
      );

    expect(sorted, <Person>[_ada, _bob, _cid]);
  });

  test('breaks ties by the next key descending', () {
    final people = <Person>[_ada, _cid, _bob];

    final sorted = List<Person>.of(people)
      ..sort(
        compareByDescending<Person, num>((person) => person.age)
            .thenByDescending((person) => person.name),
      );

    expect(sorted, <Person>[_bob, _ada, _cid]);
  });

  test('breaks ties by the reverse of another comparator', () {
    final people = <Person>[_ada, _cid, _bob];
    int byName(Person left, Person right) => left.name.compareTo(right.name);

    final sorted = List<Person>.of(people)
      ..sort(
        compareBy<Person, num>((person) => person.age).thenDescending(byName),
      );

    expect(sorted, <Person>[_cid, _bob, _ada]);
  });
}
