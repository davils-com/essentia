/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
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
