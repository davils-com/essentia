/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';
import 'package:test/test.dart';

import 'console.dart';
import 'console_dto.dart';
import 'destination.dart';
import 'workspace.dart';
import 'workspace_dto.dart';
import 'workspace_id.dart';

/// Covers data transfer objects and their mapping to the domain.
void main() {
  test('toDomain maps the transport shape onto the domain value', () {
    final Console console = const ConsoleDto(
      'stdout',
      colour: false,
    ).toDomain();

    expect(console.name, 'stdout');
    expect(console.colour, isFalse);
  });

  test('the domain type is covariant, so a list of one shape satisfies a '
      'list of the supertype', () {
    const specific = <ConsoleDto>[
      ConsoleDto('a', colour: true),
      ConsoleDto('b', colour: false),
    ];

    const List<DataTransferObject<Destination>> general = specific;

    expect(general.map((shape) => shape.toDomain().name).toList(), <String>[
      'a',
      'b',
    ]);
  });

  test('a whole answer from a data source is mapped in one call', () {
    const page = <ConsoleDto>[
      ConsoleDto('a', colour: true),
      ConsoleDto('b', colour: false),
    ];

    final List<Console> consoles = page.toDomain();

    expect(consoles.map((console) => console.name).toList(), <String>[
      'a',
      'b',
    ]);
    expect(consoles.map((console) => console.colour).toList(), <bool>[
      true,
      false,
    ]);
  });

  test('mapping an empty answer yields an empty list', () {
    expect(<ConsoleDto>[].toDomain(), isEmpty);
  });

  test('a valid shape passes the boundary in one step', () {
    const dto = WorkspaceDto('w-1', 'staging', 'nils');

    final Workspace workspace = dto.validateOrThrow('workspace').toDomain();

    expect(workspace, const Workspace(WorkspaceId('w-1'), 'staging', 'nils'));
  });

  test('a shape with three problems is rejected once, naming all three', () {
    final dto = WorkspaceDto('', 'x' * (WorkspaceDto.maxNameLength + 1), '');

    expect(
      () => dto.validateOrThrow('workspace'),
      throwsA(
        isA<ValidationException>().having(
          (failure) => failure.report.errors
              .map((violation) => violation.path.toString())
              .toList(),
          'error paths',
          <String>['id', 'name', 'owner'],
        ),
      ),
    );
  });
}
