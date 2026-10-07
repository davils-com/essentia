/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:math';

import 'package:essentia/essentia.dart';
import 'package:test/test.dart';

import 'job_model.dart';
import 'job_node.dart';
import 'job_operation.dart';

/// Builds a tree of [size] jobs with [random] parents and supervisors.
///
/// Returns the nodes, every parent before its children.
List<JobNode> _tree(Random random, int size) {
  final nodes = <JobNode>[];
  for (var index = 0; index < size; index++) {
    final JobNode? parent = index == 0
        ? null
        : nodes[random.nextInt(nodes.length)];
    final bool isSupervisor = random.nextInt(10) < 3;
    final Job? parentJob = parent?.job;
    final CompletableJob job = isSupervisor
        ? SupervisorJob(parentJob)
        : CompletableJob(parentJob);
    final node = JobNode(job, parent, isSupervisor: isSupervisor);
    parent?.children.add(node);
    job
      ..invokeOnCompletion((cause) {
        node.completions.add(cause);
        if (node.children.any((child) => !child.job.isCompleted)) {
          node.completedBeforeChildren = true;
        }
      })
      ..invokeOnCompletion((cause) => node.cancellings++, onCancelling: true);
    nodes.add(node);
  }
  return nodes;
}

/// Checks every node of [nodes] against the model, after [step].
void _check(List<JobNode> nodes, String step) {
  for (final node in nodes) {
    final reason = '$node at node ${nodes.indexOf(node)} after $step';
    final CompletableJob job = node.job;
    expect(job.isCompleted, node.isFinal, reason: 'isCompleted of $reason');
    expect(job.isCancelled, node.cancelling, reason: 'isCancelled of $reason');
    expect(
      job.isActive,
      !node.cancelling && !node.isFinal,
      reason: 'isActive of $reason',
    );
    expect(node.completedBeforeChildren, isFalse, reason: 'order of $reason');
    if (!node.isFinal) {
      expect(node.completions, isEmpty, reason: 'handler of $reason');
      continue;
    }
    expect(node.completions, hasLength(1), reason: 'handler of $reason');
    final Object? failure = node.failure;
    final Object? cause = node.completions.single;
    if (failure != null) {
      expect(cause, same(failure), reason: 'final cause of $reason');
      continue;
    }
    if (node.cancelling) {
      expect(cause, isA<CancellationException>(), reason: 'cause of $reason');
      continue;
    }
    expect(cause, isNull, reason: 'cause of $reason');
  }
  for (final node in nodes) {
    expect(
      node.cancellings,
      node.cancelling || node.isFinal ? 1 : 0,
      reason: 'cancelling handler of $node after $step',
    );
  }
}

/// Covers invariants of the job tree over generated trees and events: a
/// parent is final only after all its children, the first failure that is
/// not a cancellation is the final cause, a supervisor isolates its
/// children, every handler runs exactly once, and a job is completed
/// exactly when it reached its final state.
void main() {
  test('holds the job contract over generated trees and events', () {
    final random = Random(20261007);
    for (var round = 0; round < 300; round++) {
      final model = JobModel();
      final List<JobNode> nodes = _tree(random, 2 + random.nextInt(12));
      final steps = <String>[];
      for (var event = 0; event < 3 + random.nextInt(10); event++) {
        final JobNode node = nodes[random.nextInt(nodes.length)];
        switch (JobOperation.values[random.nextInt(
          JobOperation.values.length,
        )]) {
          case JobOperation.cancel:
            steps.add('cancel ${nodes.indexOf(node)}');
            model.cancel(node);
            node.job.cancel();
          case JobOperation.complete:
            steps.add('complete ${nodes.indexOf(node)}');
            model.complete(node);
            node.job.complete();
          case JobOperation.fail:
            final failure = StateError('failure $round.$event');
            steps.add('fail ${nodes.indexOf(node)}');
            model.fail(node, failure);
            node.job.completeExceptionally(failure);
        }
        _check(nodes, 'round $round: ${steps.join(', ')}');
      }
      for (final JobNode node in nodes.reversed) {
        model.complete(node);
        node.job.complete();
      }
      _check(nodes, 'round $round, completing everything');
      expect(nodes.every((node) => node.job.isCompleted), isTrue);
    }
  });
}
