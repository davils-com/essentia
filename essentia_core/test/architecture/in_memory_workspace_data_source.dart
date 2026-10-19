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
