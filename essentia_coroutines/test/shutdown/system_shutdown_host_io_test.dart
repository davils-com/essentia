/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

@TestOn('vm')
library;

import 'dart:async';

import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:test/test.dart';

/// Covers `ShutdownHost.system` where `dart:io` is.
void main() {
  test('watches the signals of the process until cancelled', () async {
    final StreamSubscription<ShutdownSignal> subscription = ShutdownHost.system
        .watch()
        .listen((_) {});

    await subscription.cancel();
  });
}
