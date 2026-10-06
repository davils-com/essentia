/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'workspace_data_source.dart';
import 'workspace_dto.dart';

/// A [WorkspaceDataSource] keeping its workspaces in a list.
final class InMemoryWorkspaceDataSource implements WorkspaceDataSource {
  /// Creates the source holding [initial].
  InMemoryWorkspaceDataSource([List<WorkspaceDto> initial = const []])
    : _stored = List<WorkspaceDto>.of(initial);

  /// What is stored, in the order it was written.
  final List<WorkspaceDto> _stored;

  /// A copy of what is stored.
  List<WorkspaceDto> get written => List<WorkspaceDto>.unmodifiable(_stored);

  /// Reads every stored workspace.
  @override
  Future<List<WorkspaceDto>> findAll() =>
      Future<List<WorkspaceDto>>.value(written);

  /// Stores [workspace], replacing one with the same identifier.
  @override
  Future<bool> upsert(WorkspaceDto workspace) {
    _stored
      ..removeWhere((stored) => stored.id == workspace.id)
      ..add(workspace);
    return Future<bool>.value(true);
  }
}
