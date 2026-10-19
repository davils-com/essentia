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

import 'package:essentia_core/essentia_core.dart';
import 'package:essentia_coroutines/src/context/coroutine_context_zone.dart';
import 'package:essentia_coroutines/src/principal/principal_element.dart';
import 'package:essentia_coroutines/src/principal/principal_missing_exception.dart';

/// Runs [body] as [principal], so that [currentPrincipal] answers it
/// anywhere inside, however deep in its asynchronous work.
///
/// The principal is laid over the coroutine context as a `PrincipalElement`,
/// which travels in a forked `Zone`, so it reaches every `await`, `Future`,
/// `Timer`, microtask and stream listener started inside [body], and nothing
/// outside it. An inner call replaces the principal for its own body only; the
/// outer one is current again once that body is done.
///
/// Call it at exactly one place: the edge that verified who the caller is.
/// Everything below that edge reads the principal; nothing below it creates
/// one.
///
/// ```dart
/// Future<Response> handle(Request request) async {
///   final Principal? caller = authenticate(request);
///   if (caller == null) {
///     return Response.unauthorized();
///   }
///   return runAsPrincipal(caller, () => route(request));
/// }
/// ```
///
/// [body] may be synchronous or return a `Future`; an asynchronous body's
/// future is returned unchanged, so awaiting the result awaits the body.
///
/// Returns what [body] returns.
R runAsPrincipal<R>(Principal principal, R Function() body) =>
    runWithContext(PrincipalElement(principal), body);

/// The principal the current code is working for.
///
/// It reads the coroutine context and never has to wait.
///
/// Returns the principal of the innermost enclosing [runAsPrincipal], or
/// `null` when nobody put one there - which a caller has to treat as
/// "unknown", never as "anybody".
Principal? currentPrincipal() =>
    currentCoroutineContext().get(PrincipalElement.key)?.principal;

/// The principal the current code is working for, where code cannot work
/// without one.
///
/// Returns the principal of the innermost enclosing [runAsPrincipal].
///
/// Throws a [PrincipalMissingException] if there is none - the edge that
/// establishes the caller has not run for this call.
Principal requirePrincipal() {
  final Principal? principal = currentPrincipal();
  if (principal == null) {
    throw const PrincipalMissingException();
  }
  return principal;
}
