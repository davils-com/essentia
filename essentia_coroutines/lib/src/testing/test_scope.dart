/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/src/scope/coroutine_scope.dart';
import 'package:essentia_coroutines/src/testing/test_scheduler.dart';

/// The scope the body of `runTest` runs in.
///
/// Its coroutines run on the virtual time of [testScheduler]. Work that
/// runs for the whole test, such as a collector, is started in
/// [backgroundScope], which is cancelled once the test body is done.
abstract interface class TestScope implements CoroutineScope {
  /// The scheduler whose virtual time the test runs on.
  TestScheduler get testScheduler;

  /// A scope for work that runs alongside the test and is cancelled when
  /// it ends; its failures fail the test.
  CoroutineScope get backgroundScope;
}
