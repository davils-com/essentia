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

import 'counting_resource.dart';
import 'failing_resource.dart';

/// Covers `use` and `useAsync` on a `Disposable`.
void main() {
  group('use', () {
    test('returns what the block returns and disposes afterwards', () {
      final resource = CountingResource();
      var releasedInBlock = true;

      final int result = resource.use((it) {
        releasedInBlock = it.released;
        return 7;
      });

      expect(result, 7);
      expect(releasedInBlock, isFalse);
      expect(resource.disposals, 1);
    });

    test('disposes when the block fails and throws the failure on', () {
      final resource = CountingResource();

      expect(
        () => resource.use<void>((it) => throw const FormatException('x')),
        throwsFormatException,
      );
      expect(resource.disposals, 1);
    });

    test('keeps the failure of the block over a failing disposal', () {
      final resource = FailingResource();

      expect(
        () => resource.use<void>((it) => throw const FormatException('x')),
        throwsFormatException,
      );
      expect(resource.attempts, 1);
    });

    test('throws a failing disposal after a block that succeeded', () {
      final resource = FailingResource();

      expect(() => resource.use((it) => 1), throwsStateError);
      expect(resource.attempts, 1);
    });

    test('refuses a block that returns a future, after disposing', () {
      final resource = CountingResource();

      expect(
        () => resource.use((it) => Future<int>.error(StateError('late'))),
        throwsArgumentError,
      );
      expect(resource.disposals, 1);
    });
  });

  group('useAsync', () {
    test('disposes only once the future of the block completed', () async {
      final resource = CountingResource();
      var releasedInBlock = true;

      final int result = await resource.useAsync((it) async {
        await Future<void>.delayed(Duration.zero);
        releasedInBlock = it.released;
        return 3;
      });

      expect(result, 3);
      expect(releasedInBlock, isFalse);
      expect(resource.disposals, 1);
    });

    test('takes a block that returns at once', () async {
      final resource = CountingResource();

      expect(await resource.useAsync((it) => 'now'), 'now');
      expect(resource.disposals, 1);
    });

    test('disposes when the block fails and throws the failure on', () async {
      final resource = CountingResource();

      await expectLater(
        resource.useAsync<void>(
          (it) => Future<void>.error(const FormatException('x')),
        ),
        throwsFormatException,
      );
      expect(resource.disposals, 1);
    });

    test('keeps the failure of the block over a failing disposal', () async {
      final resource = FailingResource();

      await expectLater(
        resource.useAsync<void>(
          (it) => Future<void>.error(const FormatException('x')),
        ),
        throwsFormatException,
      );
      expect(resource.attempts, 1);
    });

    test('throws a failing disposal after a block that succeeded', () async {
      final resource = FailingResource();

      await expectLater(
        resource.useAsync((it) => Future<int>.value(1)),
        throwsStateError,
      );
      expect(resource.attempts, 1);
    });
  });
}
