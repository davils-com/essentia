/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
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
