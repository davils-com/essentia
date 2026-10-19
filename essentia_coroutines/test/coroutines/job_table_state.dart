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

/// The states of a job in the state table of the job state test, as
/// `toString` renders them.
enum JobTableState {
  /// A lazily started coroutine that was not started yet.
  fresh('new', isActive: false, isCompleted: false, isCancelled: false),

  /// A coroutine whose body runs.
  active('active', isActive: true, isCompleted: false, isCancelled: false),

  /// A coroutine whose body is done, waiting for a child.
  completing(
    'completing',
    isActive: true,
    isCompleted: false,
    isCancelled: false,
  ),

  /// A cancelled coroutine whose body still runs.
  cancelling(
    'cancelling',
    isActive: false,
    isCompleted: false,
    isCancelled: true,
  ),

  /// A coroutine that was finally cancelled or failed.
  cancelled('cancelled', isActive: false, isCompleted: true, isCancelled: true),

  /// A coroutine that finally completed.
  completed(
    'completed',
    isActive: false,
    isCompleted: true,
    isCancelled: false,
  );

  /// Creates the state rendered as [label], with its flags.
  const JobTableState(
    this.label, {
    required this.isActive,
    required this.isCompleted,
    required this.isCancelled,
  });

  /// How `toString` renders the state.
  final String label;

  /// What `isActive` answers in the state.
  final bool isActive;

  /// What `isCompleted` answers in the state.
  final bool isCompleted;

  /// What `isCancelled` answers in the state.
  final bool isCancelled;
}
