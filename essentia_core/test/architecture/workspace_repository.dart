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

import 'workspace.dart';
import 'workspace_data_source.dart';
import 'workspace_mapper.dart';

/// Everything the program does with workspaces, in the domain's own types.
final class WorkspaceRepository implements Repository<Workspace> {
  /// Creates the repository reading and writing through [_source].
  const WorkspaceRepository(this._source);

  /// Where the workspaces are stored.
  final WorkspaceDataSource _source;

  /// Reads every workspace.
  ///
  /// Returns the workspaces.
  Future<List<Workspace>> all() async => (await _source.findAll()).toDomain();

  /// Stores [workspace].
  ///
  /// Returns whether it was stored.
  Future<bool> save(Workspace workspace) =>
      _source.upsert(const WorkspaceMapper().fromDomain(workspace));
}
