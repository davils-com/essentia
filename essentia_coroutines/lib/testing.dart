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
