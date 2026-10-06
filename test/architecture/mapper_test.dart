/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:math';

import 'package:test/test.dart';

import 'console.dart';
import 'console_dto.dart';
import 'console_mapper.dart';
import 'in_memory_workspace_data_source.dart';
import 'workspace.dart';
import 'workspace_dto.dart';
import 'workspace_id.dart';
import 'workspace_mapper.dart';
import 'workspace_repository.dart';

/// How many generated cases the round trip is checked against.
const _cases = 500;

/// Draws a string of one to [WorkspaceDto.maxNameLength] characters, mixing
/// printable ASCII with characters outside the basic plane.
String _text(Random random) {
  final int length = 1 + random.nextInt(WorkspaceDto.maxNameLength);
  final text = StringBuffer();
  for (var position = 0; position < length; position++) {
    final wide = random.nextInt(8) == 0;
    text.writeCharCode(
      wide ? 0x1F300 + random.nextInt(0x200) : 0x20 + random.nextInt(0x5F),
    );
  }
  return text.toString();
}

/// Ports `MapperTest`.
void main() {
  test('a mapper writes the domain value back into the shape that carries '
      'it', () {
    const workspace = Workspace(WorkspaceId('w-1'), 'staging', 'nils');

    expect(
      const WorkspaceMapper().fromDomain(workspace),
      const WorkspaceDto('w-1', 'staging', 'nils'),
    );
  });

  test('the two halves undo each other, for every value the pairing '
      'carries', () {
    final random = Random(7);
    for (var round = 0; round < _cases; round++) {
      final dto = WorkspaceDto(_text(random), _text(random), _text(random));

      expect(const WorkspaceMapper().fromDomain(dto.toDomain()), dto);
    }
  });

  test('a mapper is as small as the pairing it maps', () {
    expect(
      const ConsoleMapper().fromDomain(const Console('stdout', colour: true)),
      const ConsoleDto('stdout', colour: true),
    );
  });

  test('a repository reads through the shape and writes through the '
      'mapper', () async {
    final source = InMemoryWorkspaceDataSource(const <WorkspaceDto>[
      WorkspaceDto('w-1', 'staging', 'nils'),
    ]);
    final repository = WorkspaceRepository(source);

    expect(await repository.all(), <Workspace>[
      const Workspace(WorkspaceId('w-1'), 'staging', 'nils'),
    ]);

    expect(
      await repository.save(
        const Workspace(WorkspaceId('w-2'), 'prod', 'nils'),
      ),
      isTrue,
    );

    expect(source.written, <WorkspaceDto>[
      const WorkspaceDto('w-1', 'staging', 'nils'),
      const WorkspaceDto('w-2', 'prod', 'nils'),
    ]);
  });
}
