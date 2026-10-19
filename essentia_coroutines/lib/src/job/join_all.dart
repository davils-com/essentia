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

import 'package:essentia_coroutines/src/exception/cancellation_exception.dart';
import 'package:essentia_coroutines/src/job/job.dart';

/// Waiting for a collection of jobs.
extension JoinAll on Iterable<Job> {
  /// Waits until every job is complete, one after another.
  ///
  /// Returns a future that completes once all are.
  ///
  /// Throws a [CancellationException] if the waiting code is cancelled.
  Future<void> joinAll() async {
    for (final Job job in toList()) {
      await job.join();
    }
  }
}
