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

import 'package:essentia_core/essentia_core.dart';

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
