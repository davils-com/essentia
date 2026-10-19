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
