/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// Testing coroutines on virtual time.
///
/// `runTest` runs a test body as a coroutine on the virtual event loop of a
/// `TestScheduler`: delays, timers and timeouts take no real time, and the
/// test fails with every failure of the coroutines it started.
library;

export 'src/testing/fake_shutdown_host.dart';
export 'src/testing/run_test.dart';
export 'src/testing/standard_test_dispatcher.dart';
export 'src/testing/test_dispatcher.dart';
export 'src/testing/test_scheduler.dart';
export 'src/testing/test_scope.dart';
export 'src/testing/test_scope_time.dart';
export 'src/testing/uncompleted_coroutines_error.dart';
export 'src/testing/unconfined_test_dispatcher.dart';
