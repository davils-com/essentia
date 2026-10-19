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

import 'package:essentia_coroutines/src/coroutine/abstract_coroutine.dart';
import 'package:essentia_coroutines/src/scope/coroutine_scope.dart';
import 'package:essentia_coroutines/src/testing/test_scheduler.dart';
import 'package:essentia_coroutines/src/testing/test_scope.dart';
import 'package:meta/meta.dart';

/// The coroutine the body of `runTest` runs as.
@internal
final class TestScopeImpl extends AbstractCoroutine<void> implements TestScope {
  /// Creates the scope with [parentContext] on [testScheduler], whose
  /// background work runs in [backgroundScope].
  TestScopeImpl(
    super.parentContext, {
    required this.testScheduler,
    required this.backgroundScope,
  }) : super(active: true);

  /// The scheduler whose virtual time the test runs on.
  @override
  final TestScheduler testScheduler;

  /// The scope of the work that runs alongside the test.
  @override
  final CoroutineScope backgroundScope;

  /// A failure of the test is thrown by `runTest`, not reported.
  @override
  bool get isScopedCoroutine => true;

  /// Names the kind of coroutine.
  @override
  String get kind => 'TestScope';
}
