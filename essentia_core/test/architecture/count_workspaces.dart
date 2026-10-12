/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';

import 'workspace_repository.dart';

/// Counts the workspaces, a use case without an input.
final class CountWorkspaces implements UseCase<void, int> {
  /// Creates the use case counting what [_workspaces] holds.
  const CountWorkspaces(this._workspaces);

  /// Where the workspaces are.
  final WorkspaceRepository _workspaces;

  /// Counts the workspaces.
  @override
  Future<int> call(void input) async => (await _workspaces.all()).length;
}
