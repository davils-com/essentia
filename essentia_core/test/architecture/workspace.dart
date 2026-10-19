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
import 'package:meta/meta.dart';

import 'workspace_id.dart';

/// A workspace, the domain model of the layering tests.
@immutable
final class Workspace implements DomainModel {
  /// Creates the workspace [id] called [name] and owned by [owner].
  const Workspace(this.id, this.name, this.owner);

  /// The identity of the workspace.
  final WorkspaceId id;

  /// What the workspace is called.
  final String name;

  /// Who owns the workspace.
  final String owner;

  /// A copy of this workspace called [newName].
  ///
  /// Returns the renamed copy.
  Workspace renamed(String newName) => Workspace(id, newName, owner);

  /// Two workspaces are equal when their parts are.
  @override
  bool operator ==(Object other) =>
      other is Workspace &&
      id == other.id &&
      name == other.name &&
      owner == other.owner;

  /// The hash of the parts.
  @override
  int get hashCode => Object.hash(id, name, owner);

  /// Renders the workspace for a failure message.
  @override
  String toString() => 'Workspace(id=$id, name=$name, owner=$owner)';
}
