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
import 'package:test/test.dart';

import 'destination.dart';
import 'in_memory_workspace_data_source.dart';
import 'layered_destination.dart';
import 'workspace.dart';
import 'workspace_repository.dart';

/// Covers the layer markers, as far as the type system of Dart can state
/// their contract.
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
