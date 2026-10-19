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

import 'package:essentia_coroutines/src/job/job_impl.dart';
import 'package:essentia_coroutines/src/job/supervisor_job.dart';
import 'package:meta/meta.dart';

/// The job behind `SupervisorJob()`: it never takes over a failure of a
/// child.
@internal
final class SupervisorJobImpl extends JobImpl implements SupervisorJob {
  /// Creates an active supervisor, a child of [parent] if given.
  SupervisorJobImpl([super.parent]);

  /// Leaves the failure of a child to the child.
  ///
  /// Returns `false`.
  @override
  bool childCancelled(Object cause, StackTrace stackTrace) => false;

  /// Names the supervisor.
  @override
  String get debugName => 'SupervisorJob';
}
