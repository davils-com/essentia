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

import 'job_node.dart';

/// The model of the job contract the real jobs are held against.
final class JobModel {
  /// Cancels [node].
  void cancel(JobNode node) {
    if (node.isFinal || node.cancelling) {
      return;
    }
    _markCancelling(node, null);
  }

  /// Completes [node].
  void complete(JobNode node) {
    if (node.isFinal || node.cancelling || node.bodyDone) {
      return;
    }
    node.bodyDone = true;
    _tryFinalize(node);
  }

  /// Fails [node] with [failure].
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
