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

import 'draining_resource.dart';
import 'failing_async_resource.dart';

/// Covers `useAsync` on a `DisposableAsync`.
void main() {
  test('completes only once the teardown after the block settled', () async {
    final resource = DrainingResource();
    var completed = false;

    final Future<int> result = resource
        .useAsync((it) => Future<int>.value(5))
        .whenComplete(() => completed = true);
    await Future<void>.delayed(Duration.zero);

    expect(resource.disposals, 1);
    expect(completed, isFalse);

    resource.drained.complete();

    expect(await result, 5);
    expect(completed, isTrue);
  });

  test('tears down when the block fails and throws the failure on', () async {
    final resource = DrainingResource()..drained.complete();

    await expectLater(
      resource.useAsync<void>((it) => throw const FormatException('x')),
      throwsFormatException,
    );
    expect(resource.disposals, 1);
  });

  test('keeps the failure of the block over a failing teardown', () async {
    final resource = FailingAsyncResource();

    await expectLater(
      resource.useAsync<void>((it) => throw const FormatException('x')),
      throwsFormatException,
    );
    expect(resource.attempts, 1);
  });

  test('throws a failing teardown after a block that succeeded', () async {
    final resource = FailingAsyncResource();

    await expectLater(resource.useAsync((it) => 1), throwsStateError);
    expect(resource.attempts, 1);
  });
}
