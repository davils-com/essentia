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

/// Covers the scope functions `apply`, `let`, `takeIf` and
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

  group('also', () {
    test('returns the value itself after the side effect', () {
      final seen = <int>[];

      final int value = 7.also(seen.add);

      expect(value, 7);
      expect(seen, <int>[7]);
    });

    test('keeps the very same instance', () {
      final value = <int>[1];

      expect(identical(value.also((_) {}), value), isTrue);
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

  test('the functions chain into one expression', () {
    final int? port = '8080'
        .takeUnless((it) => it.isEmpty)
        ?.let(int.tryParse)
        ?.takeIf((it) => it > 0 && it < 65536);

    expect(port, 8080);
  });
}
