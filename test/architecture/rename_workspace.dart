/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';

import 'rename_workspace_input.dart';
import 'workspace.dart';
import 'workspace_repository.dart';

/// Renames a workspace, a use case with an input.
final class RenameWorkspace
    implements UseCase<RenameWorkspaceInput, Workspace> {
  /// Creates the use case working on [_workspaces].
  const RenameWorkspace(this._workspaces);

  /// Where the workspaces are.
  final WorkspaceRepository _workspaces;

  /// Renames the workspace [input] names.
  @override
  Future<Workspace> call(RenameWorkspaceInput input) async {
    final List<Workspace> all = await _workspaces.all();
    final Workspace renamed = all
        .singleWhere((workspace) => workspace.id == input.id)
        .renamed(input.name);
    await _workspaces.save(renamed);
    return renamed;
  }
}
