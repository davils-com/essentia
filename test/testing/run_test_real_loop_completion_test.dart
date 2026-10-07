/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia/testing.dart';
import 'package:test/test.dart';

/// Covers a test body that completes on the real event loop: `runTest`
/// ends as soon as it did instead of waiting for its real-time timeout.
void main() {
  test(
    'a body that ends after a root zone future finishes the test at once',
    () => runTest((it) async {
      final source = StreamController<int>();
      addTearDown(source.close);
      final StreamSubscription<int> subscription = source.stream.listen(
        (value) {},
      );

      await subscription.cancel();
    }),
    timeout: const Timeout(Duration(seconds: 10)),
  );
}
