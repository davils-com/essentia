/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/essentia_coroutines.dart';

/// A job of a generated tree, the real one beside the model of what it
/// should be.
final class JobNode {
  /// Creates the node of [job] below [parent], a supervisor if
  /// [isSupervisor].
  JobNode(this.job, this.parent, {required this.isSupervisor});

  /// The real job.
  final CompletableJob job;

  /// The parent node, `null` for the root.
  final JobNode? parent;

  /// Whether the node is a supervisor.
  final bool isSupervisor;

  /// The child nodes.
  final children = <JobNode>[];

  /// Whether the model says the node was cancelled.
  var cancelling = false;

  /// Whether the model says the node is done itself.
  var bodyDone = false;

  /// Whether the model says the node reached its final state.
  var isFinal = false;

  /// The first failure the model says reached the node.
  Object? failure;

  /// The causes the completion handler of the real job got.
  final completions = <Object?>[];

  /// How many times the cancelling handler of the real job ran.
  var cancellings = 0;

  /// Whether a child was still running when the completion handler ran.
  var completedBeforeChildren = false;

  /// Names the node by its job.
  @override
  String toString() => '$job';
}
