/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';
import 'package:test/test.dart';

import 'console.dart';
import 'console_by_name.dart';
import 'count_workspaces.dart';
import 'destination.dart';
import 'in_memory_workspace_data_source.dart';
import 'name_length.dart';
import 'rename_workspace.dart';
import 'rename_workspace_input.dart';
import 'workspace.dart';
import 'workspace_dto.dart';
import 'workspace_id.dart';
import 'workspace_repository.dart';

/// A repository over a data source holding [stored].
WorkspaceRepository _repository(List<WorkspaceDto> stored) =>
    WorkspaceRepository(InMemoryWorkspaceDataSource(stored));

/// Ports `UseCaseTest`.
void main() {
  test('a use case is called like the function it is', () async {
    final WorkspaceRepository workspaces = _repository(const <WorkspaceDto>[
      WorkspaceDto('w-1', 'staging', 'nils'),
    ]);
    final rename = RenameWorkspace(workspaces);

    final Workspace renamed = await rename(
      const RenameWorkspaceInput(WorkspaceId('w-1'), 'prod'),
    );

    expect(renamed.name, 'prod');
    expect(
      (await workspaces.all()).map((workspace) => workspace.name).toList(),
      <String>['prod'],
    );
  });

  test('a use case with no input is run with invoke', () async {
    final UseCase<void, int> count = CountWorkspaces(
      _repository(const <WorkspaceDto>[WorkspaceDto('w-1', 'a', 'b')]),
    );

    expect(await count.invoke(), 1);
  });

  test('a trivial use case is a one-line function of its input', () async {
    const UseCase<String, int> length = NameLength();

    expect(await length('staging'), 7);
  });

  test('the output is covariant, so a use case producing a subtype '
      'satisfies the supertype', () async {
    const specific = ConsoleByName();

    const UseCase<String, Destination> general = specific;

    final Destination produced = await general('stdout');
    expect(produced.name, 'stdout');
    expect(produced, isA<Console>());
  });
}
