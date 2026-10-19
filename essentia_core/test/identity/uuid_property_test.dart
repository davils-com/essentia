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

import 'dart:math';

import 'package:essentia_core/essentia_core.dart';
import 'package:test/test.dart';

/// How many cases each property is checked against.
const _cases = 200;

/// The smallest batch a property is checked against.
const _smallestBatch = 2;

/// The largest batch a property is checked against.
const _largestBatch = 500;

/// Draws a batch size between [_smallestBatch] and [_largestBatch] from
/// [random].
int _batchSize(Random random) =>
    _smallestBatch + random.nextInt(_largestBatch - _smallestBatch + 1);

/// Mints [size] time-ordered identifiers in a row.
List<UuidV7> _mintBatch(int size) =>
    List<UuidV7>.generate(size, (_) => UuidV7.random());

/// Checks the properties every identifier must hold, over many cases.
void main() {
  group('version 7 orders by when it was minted', () {
    test('a batch of any size comes out of the mint already sorted', () {
      final random = Random(42);
      for (var round = 0; round < _cases; round++) {
        final int size = _batchSize(random);
        final List<UuidV7> minted = _mintBatch(size);
        final sorted = List<UuidV7>.of(minted)..sort();

        expect(sorted, orderedEquals(minted), reason: 'size=$size');
      }
    });

    test('comparing the objects agrees with comparing their text forms', () {
      final random = Random(43);
      for (var round = 0; round < _cases; round++) {
        final int size = _batchSize(random);
        final List<UuidV7> minted = _mintBatch(size);
        final List<String> byValue = (List<UuidV7>.of(
          minted,
        )..sort()).map((identifier) => identifier.toString()).toList();
        final List<String> byText =
            minted.map((identifier) => identifier.toString()).toList()..sort();

        expect(byValue, orderedEquals(byText), reason: 'size=$size');
      }
    });
  });

  group('the text form is the whole value', () {
    test('a version 7 identifier survives being written down and read '
        'back', () {
      for (var round = 0; round < _cases; round++) {
        final minted = UuidV7.random();
        final parsed = UuidV7.parse(minted.toString());

        expect(parsed, minted, reason: '$minted');
        expect(
          parsed.epochMilliseconds,
          minted.epochMilliseconds,
          reason: '$minted',
        );
      }
    });

    test('a version 4 identifier survives being written down and read '
        'back', () {
      for (var round = 0; round < _cases; round++) {
        final minted = UuidV4.random();

        expect(UuidV4.parse(minted.toString()), minted, reason: '$minted');
      }
    });

    test('parsing without naming a version still lands on the right one', () {
      for (var round = 0; round < _cases; round++) {
        final ordered = UuidV7.random();
        final unordered = UuidV4.random();

        expect(Uuid.parse(ordered.toString()).version, UuidVersion.timeOrdered);
        expect(Uuid.parse(unordered.toString()).version, UuidVersion.random);
      }
    });

    test('the byte form survives being written down and read back', () {
      for (var round = 0; round < _cases; round++) {
        final Uuid minted = round.isEven ? UuidV7.random() : UuidV4.random();

        expect(
          Uuid.parse(minted.toString()).toBytes(),
          minted.toBytes(),
          reason: '$minted',
        );
      }
    });
  });
}
