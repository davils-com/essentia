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

/// Covers `lazy` and `lazyOf`: one computation, retry after a
/// failure, refusal of a read from inside the initializer.
void main() {
  group('lazy', () {
    test('does not run the initializer before the first read', () {
      var runs = 0;

      final Lazy<int> value = lazy(() => ++runs);

      expect(runs, 0);
      expect(value.isInitialized, isFalse);
    });

    test('runs the initializer once and keeps its result', () {
      var runs = 0;
      final Lazy<int> value = lazy(() => ++runs);

      expect(value.value, 1);
      expect(value.value, 1);
      expect(runs, 1);
      expect(value.isInitialized, isTrue);
    });

    test('keeps a null result without running the initializer again', () {
      var runs = 0;
      final Lazy<String?> value = lazy(() {
        runs++;
        return null;
      });

      expect(value.value, isNull);
      expect(value.value, isNull);
      expect(runs, 1);
      expect(value.isInitialized, isTrue);
    });

    test('runs the initializer again after it threw', () {
      var runs = 0;
      final Lazy<int> value = lazy(() {
        runs++;
        if (runs == 1) {
          throw const FormatException('first attempt');
        }
        return runs;
      });

      expect(() => value.value, throwsFormatException);
      expect(value.isInitialized, isFalse);
      expect(value.value, 2);
      expect(value.isInitialized, isTrue);
    });

    test('refuses a read from inside its own initializer', () {
      final cell = <Lazy<int>>[];
      final Lazy<int> value = lazy(() => cell.single.value + 1);
      cell.add(value);

      expect(() => value.value, throwsStateError);
      expect(value.isInitialized, isFalse);
    });

    test('can be read again once a refused read has unwound', () {
      final cell = <Lazy<int>>[];
      var reentrant = true;
      final Lazy<int> value = lazy(() {
        if (reentrant) {
          reentrant = false;
          return cell.single.value;
        }
        return 7;
      });
      cell.add(value);

      expect(() => value.value, throwsStateError);
      expect(value.value, 7);
    });

    test('renders before and after the first read', () {
      final Lazy<int> value = lazy(() => 42);

      expect(value.toString(), 'Lazy value not initialized yet.');
      expect(value.value, 42);
      expect(value.toString(), '42');
    });
  });

  group('lazyOf', () {
    test('is initialised from the start', () {
      final Lazy<String> value = lazyOf('ready');

      expect(value.isInitialized, isTrue);
      expect(value.value, 'ready');
    });

    test('renders its value', () {
      expect(lazyOf(3).toString(), '3');
    });

    test('holds a null value', () {
      final Lazy<int?> value = lazyOf(null);

      expect(value.value, isNull);
      expect(value.isInitialized, isTrue);
    });
  });
}
