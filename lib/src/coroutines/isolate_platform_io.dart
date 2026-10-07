/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';
import 'dart:io';

import 'package:essentia/src/coroutines/coroutine_context.dart';
import 'package:essentia/src/coroutines/coroutine_dispatcher.dart';
import 'package:essentia/src/coroutines/coroutine_scope.dart';
import 'package:essentia/src/coroutines/isolate_pool_dispatcher_io.dart';
import 'package:essentia/src/coroutines/isolate_pool_io.dart';
import 'package:meta/meta.dart';

/// The pool behind `Dispatchers.isolate`, one worker per processor,
/// created on first use.
final _pool = IsolatePoolIo(Platform.numberOfProcessors);

/// Whether bodies can run on worker isolates; on a native platform they
/// can.
///
/// Returns `true`.
@internal
bool isolatesAvailable() => true;

/// Runs [block] on a worker isolate of the shared pool.
///
/// Returns what [block] returns.
@internal
Future<T> runOnIsolate<T>(
  CoroutineContext context,
  FutureOr<T> Function(CoroutineScope it) block,
) => _pool.run(context, block);

/// A view of the shared pool running at most [parallelism] bodies at once.
///
/// Returns the view.
@internal
CoroutineDispatcher? limitIsolates(int parallelism) =>
    IsolatePoolDispatcherIo(_pool, parallelism);
