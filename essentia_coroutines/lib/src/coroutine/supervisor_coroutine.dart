/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/src/coroutine/scope_coroutine.dart';
import 'package:meta/meta.dart';

/// The coroutine of `supervisorScope`: the failure of a child stays with
/// the child.
@internal
final class SupervisorCoroutine<T> extends ScopeCoroutine<T> {
  /// Creates the coroutine as a child of the job of [parentContext].
  SupervisorCoroutine(super.parentContext);

  /// Leaves the failure of a child to the child.
  ///
  /// Returns `false`.
  @override
  bool childCancelled(Object cause, StackTrace stackTrace) => false;

  /// Names the kind of coroutine.
  @override
  String get kind => 'SupervisorCoroutine';
}
