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

import 'dart:async';

import 'package:essentia_coroutines/src/context/coroutine_context.dart';
import 'package:meta/meta.dart';

/// The zone value under which the coroutine context travels.
const _contextKey = #_coroutineContext;

/// The context the current code runs with.
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
/// The elements of [added] replace the ones of `currentCoroutineContext()`
/// stored under the same keys, for [body] only: they travel in a forked
/// `Zone`, so they reach every `await`, `Future`, `Timer`, microtask and
/// stream listener started inside [body], and every coroutine launched
/// there inherits them. Outside [body] the context is what it was.
///
/// ```dart
/// final String? name = runWithContext(
///   const CoroutineName('import'),
///   () => currentCoroutineContext().get(CoroutineName.key)?.name,
/// ); // 'import'
/// ```
///
/// [body] may be synchronous or return a `Future`; an asynchronous body's
/// future is returned unchanged, so awaiting the result awaits the body.
///
/// Returns what [body] returns.
R runWithContext<R>(CoroutineContext added, R Function() body) => runZoned(
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
