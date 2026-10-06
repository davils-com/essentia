/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';

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
