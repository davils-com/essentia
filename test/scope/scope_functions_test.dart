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

/// Covers the Kotlin scope functions `apply`, `let`, `takeIf` and
/// `takeUnless`.
void main() {
  group('apply', () {
    test('runs the block on the value and returns the value itself', () {
      final values = <int>[];

      final List<int> result = values.apply((it) => it.add(1));

      expect(result, same(values));
      expect(values, <int>[1]);
    });

    test('runs the block exactly once', () {
      var runs = 0;

      'value'.apply((_) => runs++);

      expect(runs, 1);
    });

    test('hands the block the very value it was called on', () {
      final values = <int>[];
      Object? seen;

      values.apply((it) => seen = it);

      expect(seen, same(values));
    });

    test('works on a value that is null', () {
      const String? missing = null;
      var runs = 0;

      final String? result = missing.apply((_) => runs++);

      expect(result, isNull);
      expect(runs, 1);
    });
  });

  group('let', () {
    test('returns what the block returns', () {
      expect('staging'.let((it) => it.length), 7);
    });

    test('hands the block the value it was called on', () {
      expect(21.let((it) => it * 2), 42);
    });

    test('maps an optional value only when it is present', () {
      const environment = <String, String>{'PORT': '8080'};

      expect(environment['PORT']?.let(int.tryParse), 8080);
      expect(environment['HOST']?.let(int.tryParse), isNull);
    });

    test('runs the block exactly once', () {
      var runs = 0;

      'value'.let((_) => runs++);

      expect(runs, 1);
    });
  });

  group('takeIf', () {
    test('keeps the value when the predicate accepts it', () {
      expect(8080.takeIf((it) => it > 0), 8080);
    });

    test('drops the value when the predicate rejects it', () {
      expect((-1).takeIf((it) => it > 0), isNull);
    });

    test('keeps the very same instance', () {
      final values = <int>[1];

      expect(values.takeIf((it) => it.isNotEmpty), same(values));
    });

    test('asks the predicate exactly once', () {
      var asked = 0;

      'value'.takeIf((_) {
        asked++;
        return true;
      });

      expect(asked, 1);
    });
  });

  group('takeUnless', () {
    test('keeps the value when the predicate rejects it', () {
      expect('staging'.takeUnless((it) => it.isEmpty), 'staging');
    });

    test('drops the value when the predicate accepts it', () {
      expect(''.takeUnless((it) => it.isEmpty), isNull);
    });

    test('keeps the very same instance', () {
      final values = <int>[1];

      expect(values.takeUnless((it) => it.isEmpty), same(values));
    });

    test('is the opposite of takeIf for every value', () {
      for (var value = -5; value <= 5; value++) {
        final kept = value.takeIf((it) => it.isEven) != null;
        final dropped = value.takeUnless((it) => it.isEven) == null;

        expect(kept, dropped, reason: '$value');
      }
    });
  });

  test('the functions chain the way Kotlin scope functions do', () {
    final int? port = '8080'
        .takeUnless((it) => it.isEmpty)
        ?.let(int.tryParse)
        ?.takeIf((it) => it > 0 && it < 65536);

    expect(port, 8080);
  });
}
