/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/coroutines/coroutine_dispatcher.dart';
import 'package:essentia/src/testing/test_scheduler.dart';

/// A dispatcher on the virtual time of a [TestScheduler], Kotlin's
/// `TestDispatcher`.
abstract class TestDispatcher extends CoroutineDispatcher {
  /// Creates the dispatcher.
  const TestDispatcher();

  /// The scheduler whose virtual time the dispatcher runs on.
  TestScheduler get scheduler;
}
