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

import 'package:essentia_coroutines/src/job/completable_job.dart';
import 'package:essentia_coroutines/src/job/job.dart';
import 'package:essentia_coroutines/src/job/supervisor_job_impl.dart';

/// A job whose children fail on their own.
///
/// A failing child neither cancels the supervisor nor its siblings; a
/// child started with `launch` reports its failure to the
/// `CoroutineExceptionHandler` of its context instead. Cancelling the
/// supervisor still cancels every child.
///
/// ```dart
/// final scope = CoroutineScope(SupervisorJob());
/// scope.launch((it) => throw StateError('only this one fails'));
/// scope.launch((it) => keepsRunning());
/// ```
abstract interface class SupervisorJob implements CompletableJob {
  /// Creates an active supervisor, a child of [parent] if given.
  factory SupervisorJob([Job? parent]) = SupervisorJobImpl;
}
