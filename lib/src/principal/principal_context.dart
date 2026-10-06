/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia/src/principal/principal.dart';
import 'package:essentia/src/principal/principal_missing_exception.dart';

/// The zone value under which the current principal travels.
const _principalKey = #_principal;

/// Runs [body] as [principal], so that [currentPrincipal] answers it
/// anywhere inside, however deep in its asynchronous work.
///
/// This is Arc's `withContext(principal) { ... }`. The principal travels in
/// a forked `Zone`, so it reaches every `await`, `Future`, `Timer`,
/// microtask and stream listener started inside [body], and nothing outside
/// it. An inner call replaces the principal for its own body only; the
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
    runZoned(body, zoneValues: <Object?, Object?>{_principalKey: principal});

/// The principal the current code is working for.
///
/// This is Arc's `currentPrincipal()`, which reads the coroutine context;
/// here it reads the current `Zone` and never has to wait.
///
/// Returns the principal of the innermost enclosing [runAsPrincipal], or
/// `null` when nobody put one there - which a caller has to treat as
/// "unknown", never as "anybody".
Principal? currentPrincipal() {
  final Object? value = Zone.current[_principalKey];
  if (value is Principal) {
    return value;
  }
  return null;
}

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
