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
