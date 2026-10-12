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
import 'package:essentia_coroutines/src/scope/coroutine_scope.dart';
import 'package:meta/meta.dart';

/// Whether bodies can run on worker isolates; where there are none, as on
/// the web, they cannot.
///
/// Returns `false`.
@internal
bool isolatesAvailable() => false;

/// Refuses to run [block] elsewhere, since there are no isolates.
///
/// Throws an [UnsupportedError].
@internal
Future<T> runOnIsolate<T>(
  CoroutineContext context,
  FutureOr<T> Function(CoroutineScope it) block,
) => throw UnsupportedError('There are no isolates on this platform');

/// No view is needed: the event loop runs one body at a time anyway.
///
/// Returns `null`.
@internal
CoroutineDispatcher? limitIsolates(int parallelism) => null;
