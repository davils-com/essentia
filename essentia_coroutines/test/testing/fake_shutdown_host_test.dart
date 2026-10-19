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

import 'dart:async';

import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:essentia_coroutines/testing.dart';
import 'package:test/test.dart';

/// Covers `FakeShutdownHost`.
void main() {
  test('an ending signal nobody watches ends the program', () {
    final host = FakeShutdownHost()
      ..raise(ShutdownSignal.interrupt)
      ..raise(ShutdownSignal.pageHide);

    expect(host.exits, <int>[130]);
    expect(host.isWatched, isFalse);
  });

  test('sends a signal to every stream listened to', () {
    final host = FakeShutdownHost();
    final first = <ShutdownSignal>[];
    final second = <ShutdownSignal>[];
    host.watch().listen(first.add);
    host.watch().listen(second.add);

    host.raise(ShutdownSignal.terminate);

    expect(first, <ShutdownSignal>[ShutdownSignal.terminate]);
    expect(second, <ShutdownSignal>[ShutdownSignal.terminate]);
    expect(host.exits, isEmpty);
  });

  test('a stream is watched only while it is listened to', () async {
    final host = FakeShutdownHost();
    final Stream<ShutdownSignal> stream = host.watch();
    expect(host.isWatched, isFalse);

    final StreamSubscription<ShutdownSignal> subscription = stream.listen(
      (_) {},
    );
    expect(host.isWatched, isTrue);

    await subscription.cancel();
    expect(host.isWatched, isFalse);
  });

  test('records the exits the program asks for', () {
    final host = FakeShutdownHost()
      ..exit(1)
      ..exit(2);

    expect(host.exits, <int>[1, 2]);
    expect(() => host.exits.add(3), throwsUnsupportedError);
  });
}
