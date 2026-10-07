/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia/src/coroutines/coroutine_context.dart';
import 'package:meta/meta.dart';

/// The zone value under which the coroutine context travels.
const _contextKey = #_coroutineContext;

/// The context the current code runs with, Kotlin's
/// `currentCoroutineContext()`.
///
/// The context travels in a `Zone`, so it reaches every `await`, `Future`,
/// `Timer`, microtask and stream listener started inside a coroutine, and
/// nothing outside it.
///
/// Returns the context of the innermost enclosing coroutine, or the empty
/// context outside every coroutine.
CoroutineContext currentCoroutineContext() => contextOfZone(Zone.current);

/// The context [zone] carries.
///
/// Returns the context, or the empty context when [zone] carries none.
@internal
CoroutineContext contextOfZone(Zone zone) {
  final Object? value = zone[_contextKey];
  if (value is CoroutineContext) {
    return value;
  }
  return CoroutineContext.empty;
}

/// Runs [body] with [added] laid over the current context, without
/// starting a coroutine.
///
/// Returns what [body] returns.
@internal
R overlayContext<R>(CoroutineContext added, R Function() body) => runZoned(
  body,
  zoneValues: <Object?, Object?>{
    _contextKey: currentCoroutineContext() + added,
  },
);

/// Forks the current zone into one that carries [context].
///
/// Returns the forked zone.
@internal
Zone forkCoroutineZone(CoroutineContext context) =>
    Zone.current.fork(zoneValues: <Object?, Object?>{_contextKey: context});
