/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';

import 'workspace_dto.dart';

/// Where workspaces are stored, in the vocabulary of the store.
abstract interface class WorkspaceDataSource implements DataSource {
  /// Reads every stored workspace.
  ///
  /// Returns the stored shapes.
  Future<List<WorkspaceDto>> findAll();

  /// Stores [workspace], replacing one with the same identifier.
  ///
  /// Returns whether it was stored.
  Future<bool> upsert(WorkspaceDto workspace);
}
