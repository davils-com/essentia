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
