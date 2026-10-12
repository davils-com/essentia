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
import 'package:essentia_coroutines/src/dispatcher/dispatchers.dart';
import 'package:essentia_coroutines/src/dispatcher/parallelism.dart';
import 'package:meta/meta.dart';

/// The dispatcher behind `Dispatchers.main`: a microtask on the event loop
/// of the isolate.
@internal
final class EventLoopDispatcher extends CoroutineDispatcher {
  /// Creates the dispatcher; there is one, `Dispatchers.main`.
  const EventLoopDispatcher();

  /// Runs [block] in a microtask of [zone].
  @override
  void dispatch(CoroutineContext context, Zone zone, void Function() block) =>
      zone.scheduleMicrotask(block);

  /// The event loop runs one body at a time anyway.
  ///
  /// Returns `Dispatchers.main`.
  ///
  /// Throws a [RangeError] if [parallelism] is smaller than one.
  @override
  CoroutineDispatcher limitedParallelism(int parallelism) {
    checkParallelism(parallelism);
    return Dispatchers.main;
  }

  /// Names the dispatcher.
  @override
  String toString() => 'Dispatchers.main';
}
