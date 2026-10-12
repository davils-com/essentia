/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia_coroutines/src/context/coroutine_context.dart';
import 'package:essentia_coroutines/src/dispatcher/coroutine_dispatcher.dart';
import 'package:meta/meta.dart';

/// The dispatcher behind `Dispatchers.unconfined`: the body starts at once,
/// in the caller's frame.
@internal
final class UnconfinedDispatcher extends CoroutineDispatcher {
  /// Creates the dispatcher; there is one, `Dispatchers.unconfined`.
  const UnconfinedDispatcher();

  /// A body never has to be dispatched.
  ///
  /// Returns `false`.
  @override
  bool isDispatchNeeded(CoroutineContext context) => false;

  /// Runs [block] in [zone] at once.
  @override
  void dispatch(CoroutineContext context, Zone zone, void Function() block) =>
      zone.run(block);

  /// A body started at once is not limited by anything, Kotlin's
  /// `Unconfined.limitedParallelism`.
  ///
  /// Throws an [UnsupportedError].
  @override
  CoroutineDispatcher limitedParallelism(int parallelism) =>
      throw UnsupportedError(
        'limitedParallelism is not supported for Dispatchers.unconfined',
      );

  /// Names the dispatcher.
  @override
  String toString() => 'Dispatchers.unconfined';
}
