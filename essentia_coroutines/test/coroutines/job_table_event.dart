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

/// What happens to a job in the state table of the job state test.
enum JobTableEvent {
  /// `start()`.
  start,

  /// `cancel()`.
  cancel,

  /// The body returns.
  complete,

  /// The body throws the failure of the probe.
  completeExceptionally,

  /// A child completes.
  childComplete,

  /// A child fails with the failure of the probe.
  childFail,
}
