/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/comparison/comparator_chaining.dart';
import 'package:essentia/src/comparison/comparison_dsl.dart';
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
