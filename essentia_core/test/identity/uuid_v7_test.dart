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
import 'package:essentia_core/src/identity/uuid_minter.dart';
import 'package:test/test.dart';

/// The canonical text form of a version 7 identifier.
final _textForm = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

/// The millisecond the controlled clock starts at.
const _start = 1700000000000;

/// More identifiers than one millisecond can hold, whatever the counter was
/// seeded with.
const _overflowing = 5000;

/// Whether every identifier in [minted] sorts strictly after the one before.
bool _strictlyAscending(List<UuidV7> minted) {
  for (var index = 1; index < minted.length; index++) {
    if (minted[index].compareTo(minted[index - 1]) <= 0) {
      return false;
    }
  }
  return true;
}

/// Tests the time-ordered identifier.
void main() {
  test('a minted identifier has the canonical version 7 text form', () {
    expect(UuidV7.random().toString(), matches(_textForm));
  });

  test('the timestamp is the moment the identifier was minted', () {
    final int before = DateTime.now().millisecondsSinceEpoch;
    final identifier = UuidV7.random();
    final int after = DateTime.now().millisecondsSinceEpoch;

    expect(identifier.epochMilliseconds, greaterThanOrEqualTo(before));
    expect(identifier.epochMilliseconds, lessThanOrEqualTo(after));
    expect(
      identifier.instant.millisecondsSinceEpoch,
      identifier.epochMilliseconds,
    );
    expect(identifier.instant.isUtc, isTrue);
  });

  test('identifiers minted in the same millisecond still order by which came '
      'first', () {
    final minted = List<UuidV7>.generate(1000, (_) => UuidV7.random());
    final sorted = List<UuidV7>.of(minted)..sort();

    expect(sorted, orderedEquals(minted));
    expect(_strictlyAscending(minted), isTrue);
  });

  test('a later identifier is greater than an earlier one', () {
    final earlier = UuidV7.random();
    final later = UuidV7.random();

    expect(later.compareTo(earlier), greaterThan(0));
    expect(earlier.compareTo(later), lessThan(0));
    expect(later.compareTo(later), 0);
  });

  test('comparison agrees with the order of the text form', () {
    final minted = List<UuidV7>.generate(500, (_) => UuidV7.random());
    final List<String> byValue = (List<UuidV7>.of(
      minted,
    )..sort()).map((identifier) => identifier.toString()).toList();
    final List<String> byText =
        minted.map((identifier) => identifier.toString()).toList()..sort();

    expect(byValue, orderedEquals(byText));
  });

  test('an identifier reads back from its text form as itself', () {
    final original = UuidV7.random();
    final parsed = UuidV7.parse(original.toString());

    expect(parsed, original);
    expect(parsed.epochMilliseconds, original.epochMilliseconds);
    expect(parsed.hashCode, original.hashCode);
  });

  test('uppercase hexadecimal reads back as the same identifier', () {
    final original = UuidV7.random();

    expect(UuidV7.parse(original.toString().toUpperCase()), original);
  });

  group('minting against a controlled clock', () {
    test('a stopped clock still mints in order, in that one millisecond', () {
      final minter = UuidMinter(Random(7), () => _start);
      final minted = List<UuidV7>.generate(
        2049,
        (_) => UuidV7.mintedBy(minter),
      );

      expect(_strictlyAscending(minted), isTrue);
      expect(
        minted.map((identifier) => identifier.epochMilliseconds).toSet(),
        <int>{_start},
      );
      expect(
        minted.every((identifier) => _textForm.hasMatch('$identifier')),
        isTrue,
      );
    });

    test('a full counter borrows the next millisecond and keeps order', () {
      final minter = UuidMinter(Random(11), () => _start);
      final minted = List<UuidV7>.generate(
        _overflowing,
        (_) => UuidV7.mintedBy(minter),
      );
      final Set<int> milliseconds = minted
          .map((identifier) => identifier.epochMilliseconds)
          .toSet();

      expect(_strictlyAscending(minted), isTrue);
      expect(milliseconds, contains(_start));
      expect(milliseconds, contains(_start + 1));
      expect(
        milliseconds.every((millisecond) => millisecond <= _start + 2),
        isTrue,
      );
      expect(
        minted.every((identifier) => _textForm.hasMatch('$identifier')),
        isTrue,
      );
    });

    test('a clock that steps back does not make an identifier go back', () {
      int now = _start;
      final minter = UuidMinter(Random(13), () => now);

      final before = UuidV7.mintedBy(minter);
      now = _start - 500;
      final afterStepBack = UuidV7.mintedBy(minter);
      now = _start + 1;
      final afterRecovery = UuidV7.mintedBy(minter);

      expect(afterStepBack.compareTo(before), greaterThan(0));
      expect(afterStepBack.epochMilliseconds, _start);
      expect(afterRecovery.compareTo(afterStepBack), greaterThan(0));
      expect(afterRecovery.epochMilliseconds, _start + 1);
    });

    test('a clock that moves on stamps the new millisecond', () {
      int now = _start;
      final minter = UuidMinter(Random(17), () => now);

      final first = UuidV7.mintedBy(minter);
      now = _start + 42;
      final second = UuidV7.mintedBy(minter);

      expect(first.epochMilliseconds, _start);
      expect(second.epochMilliseconds, _start + 42);
      expect(
        second.instant,
        DateTime.fromMillisecondsSinceEpoch(_start + 42, isUtc: true),
      );
    });
  });
}
