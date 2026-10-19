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
