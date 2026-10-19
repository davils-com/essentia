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
import 'dart:io';

import 'package:essentia_coroutines/src/context/coroutine_context.dart';
import 'package:essentia_coroutines/src/dispatcher/coroutine_dispatcher.dart';
import 'package:essentia_coroutines/src/isolate/isolate_pool_dispatcher_io.dart';
import 'package:essentia_coroutines/src/isolate/isolate_pool_io.dart';
import 'package:essentia_coroutines/src/scope/coroutine_scope.dart';
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
