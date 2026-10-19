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
import 'package:essentia_coroutines/src/scope/coroutine_scope.dart';
import 'package:meta/meta.dart';

/// A dispatcher that runs a whole body somewhere else, such as on another
/// isolate, instead of starting it on the event loop of this one.
@internal
abstract interface class RemoteDispatcher {
  /// Whether bodies really run somewhere else; when not, they start as
  /// on any other dispatcher.
  bool get remote;

  /// Runs [block] with the sendable elements of [context] and waits for its
  /// result; cancelling the job of [context] cancels it.
  ///
  /// Returns what [block] returns.
  Future<T> execute<T>(
    CoroutineContext context,
    FutureOr<T> Function(CoroutineScope it) block,
  );
}
