/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia/src/coroutines/abstract_coroutine_context_element.dart';
import 'package:essentia/src/coroutines/coroutine_context.dart';
import 'package:essentia/src/coroutines/coroutine_context_key.dart';

/// Decides where the body of a coroutine starts, Kotlin's
/// `CoroutineDispatcher`.
///
/// An isolate runs one thing at a time, so a dispatcher decides only how a
/// body is started: on the event loop, at once, or on another isolate. The
/// code after each `await` goes on in the zone of the coroutine on the
/// event loop of its isolate.
abstract class CoroutineDispatcher with AbstractCoroutineContextElement {
  /// Creates a dispatcher.
  const CoroutineDispatcher();

  /// The key a dispatcher is stored under in a coroutine context.
  static const key = CoroutineContextKey<CoroutineDispatcher>(
    'CoroutineDispatcher',
  );

  /// The key a dispatcher is stored under.
  @override
  CoroutineContextKey<CoroutineDispatcher> get contextKey => key;

  /// Whether a body started with [context] has to be dispatched, or may
  /// start at once in the caller's frame, Kotlin's `isDispatchNeeded`.
  bool isDispatchNeeded(CoroutineContext context) => true;

  /// Runs [block] in [zone] later, Kotlin's `dispatch`.
  void dispatch(CoroutineContext context, Zone zone, void Function() block);

  /// A view of this dispatcher that runs at most [parallelism] bodies at
  /// once, Kotlin's `limitedParallelism`.
  ///
  /// An isolate already runs one thing at a time, so a dispatcher of the
  /// event loop is its own view.
  ///
  /// Returns the limited dispatcher.
  ///
  /// Throws a [RangeError] if [parallelism] is smaller than one.
  CoroutineDispatcher limitedParallelism(int parallelism);
}
