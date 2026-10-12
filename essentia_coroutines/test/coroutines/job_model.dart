/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'job_node.dart';

/// The model of the job contract the real jobs are held against.
final class JobModel {
  /// Cancels [node], Kotlin's `cancel()`.
  void cancel(JobNode node) {
    if (node.isFinal || node.cancelling) {
      return;
    }
    _markCancelling(node, null);
  }

  /// Completes [node], Kotlin's `complete()`.
  void complete(JobNode node) {
    if (node.isFinal || node.cancelling || node.bodyDone) {
      return;
    }
    node.bodyDone = true;
    _tryFinalize(node);
  }

  /// Fails [node] with [failure], Kotlin's `completeExceptionally`.
  void fail(JobNode node, Object failure) {
    if (node.isFinal || node.bodyDone) {
      return;
    }
    _markCancelling(node, failure);
  }

  /// Moves [node] to cancelling for [failure], or a cancellation.
  void _markCancelling(JobNode node, Object? failure) {
    node
      ..cancelling = true
      ..bodyDone = true
      ..failure ??= failure;
    for (final JobNode child in node.children) {
      if (!child.isFinal && !child.cancelling) {
        _markCancelling(child, null);
      }
    }
    if (failure != null) {
      _failUp(node, failure);
    }
    _tryFinalize(node);
  }

  /// Hands [failure] of [node] to its parent, unless that is a supervisor.
  void _failUp(JobNode node, Object failure) {
    final JobNode? parent = node.parent;
    if (parent == null || parent.isSupervisor || parent.isFinal) {
      return;
    }
    if (parent.cancelling) {
      parent.failure ??= failure;
      return;
    }
    _markCancelling(parent, failure);
  }

  /// Moves [node] to its final state once it and its children are done.
  void _tryFinalize(JobNode node) {
    if (node.isFinal ||
        !node.bodyDone ||
        node.children.any((child) => !child.isFinal)) {
      return;
    }
    node.isFinal = true;
    final Object? failure = node.failure;
    if (failure != null) {
      _failUp(node, failure);
    }
    final JobNode? parent = node.parent;
    if (parent != null) {
      _tryFinalize(parent);
    }
  }
}
