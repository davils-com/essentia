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

import 'package:test/test.dart';

import 'counting_resource.dart';
import 'draining_resource.dart';

/// Covers the contract of `Disposable` and `DisposableAsync`.
void main() {
  group('Disposable', () {
    test('disposing releases what the object held', () {
      final resource = CountingResource()..dispose();

      expect(resource.released, isTrue);
    });

    test('disposing twice does nothing the second time and does not '
        'fail', () {
      final resource = CountingResource()..dispose();

      expect(resource.dispose, returnsNormally);
      expect(resource.disposals, 1);
    });
  });

  group('DisposableAsync', () {
    test('disposing completes only once the teardown has settled', () async {
      final resource = DrainingResource();
      var completed = false;

      final Future<void> disposal = resource.dispose().whenComplete(
        () => completed = true,
      );
      await Future<void>.delayed(Duration.zero);

      expect(resource.disposals, 1);
      expect(completed, isFalse);

      resource.drained.complete();
      await disposal;

      expect(completed, isTrue);
    });

    test('a second disposal returns once the first has settled rather than '
        'starting again', () async {
      final resource = DrainingResource();
      var secondCompleted = false;

      final Future<void> first = resource.dispose();
      final Future<void> second = resource.dispose().whenComplete(
        () => secondCompleted = true,
      );
      await Future<void>.delayed(Duration.zero);

      expect(secondCompleted, isFalse);

      resource.drained.complete();
      await first;
      await second;

      expect(secondCompleted, isTrue);
      expect(resource.disposals, 1);
    });

    test('a disposal after the teardown settled completes without starting '
        'again', () async {
      final resource = DrainingResource();
      resource.drained.complete();
      await resource.dispose();

      await resource.dispose();

      expect(resource.disposals, 1);
    });
  });
}
