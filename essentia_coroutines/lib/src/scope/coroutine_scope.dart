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

import 'package:essentia_coroutines/src/context/coroutine_context.dart';
import 'package:essentia_coroutines/src/job/job.dart';
import 'package:essentia_coroutines/src/scope/context_scope.dart';

/// What coroutines are started in, and whose job is their parent.
///
/// A scope owns the work started in it: `launch` and `async` start
/// children of its job, and cancelling the scope cancels them all. A
/// component with background work owns one scope and cancels it when it is
/// disposed.
///
/// ```dart
/// final class Indexer implements Disposable {
///   final _scope = CoroutineScope(SupervisorJob());
///
///   void start() => _scope.launch((it) => indexForever());
///
///   @override
///   void dispose() => _scope.cancel();
/// }
/// ```
abstract interface class CoroutineScope {
  /// Creates a scope with [context], adding a `Job()` when it holds none.
  factory CoroutineScope(CoroutineContext context) =>
      ContextScope(context.get(Job.key) == null ? context + Job() : context);

  /// The context every coroutine of the scope starts with.
  CoroutineContext get coroutineContext;
}
