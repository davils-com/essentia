/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
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
