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

/// An action a `Scheduler` runs later, and the handle that calls it off.
abstract interface class ScheduledTask {
  /// Whether the action still waits to run.
  ///
  /// It is `false` once the action ran or the task was cancelled.
  bool get isActive;

  /// Calls the action off if it has not run yet.
  ///
  /// Cancelling a task that already ran or was cancelled does nothing.
  void cancel();
}
