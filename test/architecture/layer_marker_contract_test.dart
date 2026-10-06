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

import 'destination.dart';
import 'in_memory_workspace_data_source.dart';
import 'layered_destination.dart';
import 'workspace.dart';
import 'workspace_repository.dart';

/// Ports what `LayerMarkerContractTest` checks by reflection, as far as
/// the type system of Dart can state it.
void main() {
  test('the markers declare nothing, so a type implements them with an '
      'empty body', () {
    const layered = LayeredDestination('stdout');

    expect(layered, isA<DataSource>());
    expect(layered, isA<Repository<Destination>>());
    expect(layered, isA<DomainModel>());
  });

  test('the markers are interfaces, so a type carries its layer beside its '
      'own supertype', () {
    const layered = LayeredDestination('stdout');

    expect(layered, isA<Destination>());
    expect(layered.name, 'stdout');
  });

  test('a repository names a domain model as its subject', () {
    final repository = WorkspaceRepository(InMemoryWorkspaceDataSource());

    expect(repository, isA<Repository<Workspace>>());
    expect(repository, isA<Repository<DomainModel>>());
  });

  test('a data source is marked as one', () {
    expect(InMemoryWorkspaceDataSource(), isA<DataSource>());
  });
}
